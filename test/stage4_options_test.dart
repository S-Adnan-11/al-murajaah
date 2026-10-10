import 'dart:async';
import 'dart:io';

import 'package:al_murajaah/core/audio/prototype_handler.dart';
import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:al_murajaah/features/product/playback_options.dart';
import 'package:al_murajaah/features/product/passage_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

import 'playback_intent_test.dart' show HeldPlayer;

class SelectionPlayer extends HeldPlayer {
  @override
  Future<void> seek(Duration? value, {int? index}) async {
    if (value != null) position = value;
    if (index != null) currentIndex = index;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('central speed and preview', () {
    late Directory root;
    late HeldPlayer player;
    late PrototypeHandler h;
    setUp(() async {
      root = await Directory.systemTemp.createTemp('stage4-options');
      player = SelectionPlayer();
      h = PrototypeHandler(
        PrototypeStore(root),
        player: player,
        localResolver: (_) async => null,
      );
    });
    tearDown(() async {
      await h.dispose();
      await root.delete(recursive: true);
    });
    SessionSpec passage({double speed = 1, int gap = 0}) => SessionSpec(
      assetId: samples.first.id,
      durationMs: 10000,
      startMs: 2000,
      endMs: 5000,
      isPassage: true,
      playCount: 3,
      speed: speed,
      gapMs: gap,
    );
    test('speed validates, persists, preserves scope/pass/position and new full playback resets defaults', () async {
      await h.loadAndStart(passage());
      player.index(1);
      player.position = const Duration(seconds: 1);
      await Future<void>.delayed(Duration.zero);
      final sources = player.audioSources;
      await h.setSpeed(.75);
      expect(player.speed, .75);
      expect(player.pitch, 1);
      expect(player.audioSources, same(sources));
      expect(h.pass, 2);
      expect(h.position, const Duration(seconds: 1));
      expect(h.spec!.playCount, 3);
      expect((await h.store.readCheckpoint())!['spec']['speed'], .75);
      await expectLater(h.setSpeed(double.nan), throwsArgumentError);
      expect(player.speed, .75);
      await h.loadAndStart(
        SessionSpec(assetId: samples.first.id, durationMs: 10000),
      );
      expect(player.speed, 1);
      expect(h.spec!.isPassage, false);
      expect(h.spec!.playCount, 1);
    });
    test('speed rescales native silence, preserving gap position/pass and sleep intent', () async {
      await h.loadAndStart(passage(gap: 2000));
      player.index(3);
      player.position = const Duration(milliseconds: 500);
      await Future<void>.delayed(Duration.zero);
      await h.setSleepTimer(const Duration(minutes: 15));
      await h.setSpeed(.9);
      expect(h.inGap, true);
      expect(h.pass, 2);
      expect(player.position.inMilliseconds, 450);
      expect(h.sleepLabel, '15 minutes');
      expect(h.spec!.playCount, 3);
      final uri = (player.audioSources[1] as UriAudioSource).uri;
      expect((await File.fromUri(uri).length()) - 44, 8000 * 2 * 1800 ~/ 1000);
      await h.setSleepTimer(null, afterPass: true);
      expect(
        h.completed,
        true,
        reason: 'after-pass during gap stops before another recitation',
      );
    });
    test('preview never overwrites checkpoint and Cancel restores original paused session and saved settings', () async {
      await h.loadAndStart(passage(speed: .9));
      player.index(1);
      player.position = const Duration(seconds: 1);
      await Future<void>.delayed(Duration.zero);
      await h.pause();
      final before = await File('${root.path}/checkpoint.json').readAsBytes();
      final preview = h.beginPreview();
      await preview.preview(
        SessionSpec(
          assetId: samples.last.id,
          durationMs: 10000,
          startMs: 1000,
          endMs: 3000,
          isPassage: true,
          speed: 1.25,
        ),
      );
      expect(await File('${root.path}/checkpoint.json').readAsBytes(), before);
      await preview.restore();
      expect(h.spec!.assetId, samples.first.id);
      expect(h.spec!.speed, .9);
      expect(h.pass, 2);
      expect(h.position, const Duration(seconds: 1));
      expect(h.playing, false);
      expect(h.spec!.startMs, 2000);
      expect(h.spec!.endMs, 5000);
    });
    test('paused full-surah audition and its own seek/pause restore original progress, options, metadata and deadline', () async {
      final original = passage(
        speed: .9,
        gap: 2000,
      ).withPassage('saved-id', 'Saved name');
      await h.loadAndStart(original);
      player.index(2);
      player.position = const Duration(milliseconds: 1000);
      await Future<void>.delayed(Duration.zero);
      await h.setSleepTimer(const Duration(minutes: 15));
      await h.pause();
      final deadline = DateTime.parse(
        h.diagnostics['sleepDeadlineUtc'] as String,
      );
      final checkpoint = await File('${root.path}/checkpoint.json')
          .readAsBytes();
      final preview = h.beginPreview();
      final playsBefore = player.plays;
      final metadata = h.mediaItem.value!;
      await preview.preview(
        SessionSpec(
          assetId: samples.first.id,
          durationMs: 10000,
          startMs: 5000,
          endMs: 9000,
          isPassage: true,
        ),
        autoPlay: false,
      );
      expect(h.playing, false);
      expect(player.plays, playsBefore);
      expect(preview.ownsPlayback, true);
      await preview.seek(const Duration(milliseconds: 2000));
      expect(preview.ownsPlayback, true);
      expect(h.spec!.relativeToSource(h.position.inMilliseconds), 7000);
      await preview.setPlaying(true);
      await preview.setPlaying(false);
      expect(preview.ownsPlayback, true);
      expect(
        await File('${root.path}/checkpoint.json').readAsBytes(),
        checkpoint,
      );
      await preview.restore();
      expect(h.spec!.passageId, 'saved-id');
      expect(h.spec!.startMs, 2000);
      expect(h.spec!.endMs, 5000);
      expect(h.spec!.gapMs, 2000);
      expect(h.spec!.speed, .9);
      expect(h.pass, 2);
      expect(h.position.inMilliseconds, 1000);
      expect(h.playing, false);
      expect(h.sleepLabel, isNot('Off'));
      expect(
        DateTime.parse(h.diagnostics['sleepDeadlineUtc'] as String)
            .difference(deadline)
            .inMilliseconds
            .abs(),
        lessThan(500),
      );
      expect(h.mediaItem.value!.id, original.assetId);
      expect(h.mediaItem.value!.title, metadata.title);
      expect(h.mediaItem.value!.album, metadata.album);
      expect(preview.ownsPlayback, false);
    });
    test('notification Pause still invalidates preview rollback after its own seek', () async {
      await h.loadAndStart(passage());
      final preview = h.beginPreview();
      await preview.preview(passage(speed: .75));
      await preview.seek(const Duration(milliseconds: 500));
      expect(preview.ownsPlayback, true);
      await h.pause();
      expect(preview.ownsPlayback, false);
      final loads = player.loads;
      await preview.restore();
      expect(h.playing, false);
      expect(player.loads, loads);
    });
    test(
      'Cancel cannot undo a newer source or restart a preview stopped by user',
      () async {
        await h.loadAndStart(passage());
        final preview = h.beginPreview();
        await preview.preview(passage(speed: .75));
        await h.stop();
        await preview.restore();
        expect(h.playing, false);
        final another = h.beginPreview();
        await another.preview(passage());
        await h.loadAndStart(
          SessionSpec(assetId: samples.last.id, durationMs: 10000),
        );
        await another.restore();
        expect(h.spec!.assetId, samples.last.id);
        expect(h.playing, true);
      },
    );
    test('preview with no prior session returns to empty without creating a checkpoint', () async {
      final preview = h.beginPreview();
      await preview.preview(passage());
      await preview.restore();
      expect(h.spec, isNull);
      expect(h.playing, false);
      expect(h.mediaItem.value, isNull);
      expect(await File('${root.path}/checkpoint.json').exists(), false);
    });
    test(
      'Stop during held preview restoration prevents late original playback',
      () async {
        await h.loadAndStart(passage());
        final preview = h.beginPreview();
        await preview.preview(passage(speed: .75));
        player.loading = Completer<void>();
        final restoring = preview.restore();
        await Future<void>.delayed(Duration.zero);
        final stopping = h.stop();
        final playsBefore = player.plays;
        player.loading!.complete();
        await restoring;
        await stopping;
        expect(h.playing, false);
        expect(player.plays, playsBefore);
      },
    );
    test('Cancel while preview loads restores original without playing a late preview', () async {
      await h.loadAndStart(passage());
      await h.pause();
      final preview = h.beginPreview();
      player.loading = Completer<void>();
      final pending = preview.preview(passage(speed: .75));
      await Future<void>.delayed(Duration.zero);
      final restoring = preview.restore();
      final playsBefore = player.plays;
      player.loading!.complete();
      await pending;
      await restoring;
      expect(h.spec!.speed, 1);
      expect(h.playing, false);
      expect(player.plays, playsBefore);
    });
    test('deadline immediate-pause choice preserves pass rather than waiting for its end', () async {
      await h.loadAndStart(passage());
      await h.setSleepTimer(
        const Duration(milliseconds: 30),
        finishCurrentPass: false,
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(h.playing, false);
      expect(h.pass, 1);
      expect(h.completed, false);
    });
    test('legacy default serialization stays byte-equivalent and preserves nondefault options', () {
      final old = passage().toJson();
      expect(old.containsKey('speed'), false);
      expect(SessionSpec.fromJson(old).speed, 1);
      expect(SessionSpec.fromJson(passage(speed: .9).toJson()).speed, .9);
    });
  });

  testWidgets(
    'dirty editor Back offers Keep editing then Discard without saving or playing',
    (tester) async {
      PassageDraft? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDialog<PassageDraft>(
                    context: ctx,
                    builder: (_) => PassageEditor(
                      spec: SessionSpec(assetId: 'test', durationMs: 10000),
                      title: 'Original',
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Fine-tune'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fine-tune'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'B · time in full surah'),
        '5',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Discard passage edits?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.widgetWithText(TextField, 'B · time in full surah'),
            )
            .controller!
            .text,
        '5',
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard edits'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(find.text('Set passage'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'active options retain rate/gap changes and immediate sleep choice at large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaybackOptions(
              spec: SessionSpec(
                assetId: 'test',
                durationMs: 10000,
                startMs: 2000,
                endMs: 5000,
                isPassage: true,
              ),
              active: true,
              sleepLabel: 'Off',
              finishCurrentPass: true,
              canSleep: true,
              onSleep: (m, finish) async {
                expect(m, 15);
                expect(finish, false);
                calls++;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('0.75×'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Finish current pass at deadline'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('15 minutes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15 minutes'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
