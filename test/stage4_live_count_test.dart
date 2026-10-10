import 'dart:io';

import 'package:al_murajaah/core/audio/prototype_handler.dart';
import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

import 'playback_intent_test.dart' show HeldPlayer;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late HeldPlayer player;
  late PrototypeHandler h;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('live-count');
    player = HeldPlayer();
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
  SessionSpec passage({int? count = 5, int gap = 0}) => SessionSpec(
    assetId: samples.first.id,
    durationMs: 10000,
    startMs: 2000,
    endMs: 5000,
    isPassage: true,
    playCount: count,
    gapMs: gap,
  );
  Future<void> index(int i) async {
    player.index(i);
    await Future<void>.delayed(Duration.zero);
  }

  test('editing completed passage preserves final pass/source and never starts playback', () async {
    await h.loadAndStart(passage(count: 3).withPassage('saved', 'Original'));
    await index(2);
    player.position = const Duration(milliseconds: 3000);
    player.processingState = ProcessingState.completed;
    player.events.add(player.playbackEvent);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(h.completed, true);
    final plays = player.plays;
    await h.applySavedPassage(
      SessionSpec(
        assetId: samples.first.id,
        durationMs: 10000,
        startMs: 1500,
        endMs: 6000,
        isPassage: true,
        playCount: 33,
        passageId: 'saved',
        passageTitle: 'Revised',
      ),
    );
    expect(h.completed, true);
    expect(h.pass, 3);
    expect(h.position.inMilliseconds, 3500);
    expect(h.spec!.relativeToSource(h.position.inMilliseconds), 5000);
    expect(h.playing, false);
    expect(player.plays, plays);
  });

  for (final gap in [0, 2000]) {
    for (final paused in [false, true]) {
      test(
        'saved boundary edits retain source/pass/intent, gap=$gap paused=$paused',
        () async {
          await h.loadAndStart(
            passage(gap: gap).withPassage('saved', 'Original'),
          );
          await index(gap == 0 ? 2 : 4);
          player.position = const Duration(milliseconds: 1200);
          if (paused) await h.pause();
          await h.setSleepTimer(const Duration(minutes: 15));
          final originalSource = h.diagnostics['sourceUri'];
          final loads = player.loads, pauses = player.pauses;
          SessionSpec revised(int a, int b, int? count) => SessionSpec(
            assetId: samples.first.id,
            durationMs: 10000,
            startMs: a,
            endMs: b,
            isPassage: true,
            playCount: count,
            gapMs: gap,
            passageId: 'saved',
            passageTitle: 'Revised',
          );
          await h.applySavedPassage(revised(2500, 7000, 33));
          expect(h.pass, 3);
          expect(h.position.inMilliseconds, 700);
          expect(h.spec!.relativeToSource(h.position.inMilliseconds), 3200);
          expect(h.playing, !paused);
          expect(h.spec!.playCount, 33);
          expect(h.diagnostics['sourceUri'], originalSource);
          expect(
            player.loads,
            loads + 1,
            reason: 'Immutable clips require one replacement',
          );
          expect(h.sleepLabel, '15 minutes');
          final nativeClip =
              player.audioSources[player.currentIndex!] as ClippingAudioSource;
          expect(nativeClip.start!.inMilliseconds, 2500);
          expect(nativeClip.end!.inMilliseconds, 7000);
          await h.applySavedPassage(revised(4500, 8000, 2));
          expect(h.position, Duration.zero);
          expect(h.pass, 3);
          expect(h.playing, !paused);
          expect(player.loads, loads + 2);
          expect(player.mode, LoopMode.off);
          expect(player.audioSources.length, player.currentIndex! + 1);
          expect(player.pauses, pauses + 2);
          final titleLoads = player.loads, titlePauses = player.pauses;
          await h.applySavedPassage(h.spec!.withPassage('saved', 'Title only'));
          expect(player.loads, titleLoads);
          expect(player.pauses, titlePauses);
          expect(h.pass, 3);
          expect(h.playing, !paused);
        },
      );
    }
    for (final paused in [false, true]) {
      test(
        'live 3 of 5 becomes 3 of 33, gap=$gap paused=$paused; no reload, pause, seek or count reset',
        () async {
          await h.loadAndStart(passage(gap: gap));
          await index(gap == 0 ? 2 : 4);
          player.position = const Duration(milliseconds: 750);
          if (paused) await h.pause();
          await h.setSleepTimer(const Duration(minutes: 15));
          final source = player.audioSources[player.currentIndex!];
          final loads = player.loads,
              pauses = player.pauses,
              plays = player.plays;
          await h.updateCount(33);
          expect(h.pass, 3);
          expect(h.spec!.playCount, 33);
          expect(h.position.inMilliseconds, 750);
          expect(h.playing, !paused);
          expect(player.loads, loads);
          expect(player.pauses, pauses);
          expect(player.plays, plays);
          expect(player.audioSources[player.currentIndex!], same(source));
          expect(player.audioSources.length, gap == 0 ? 33 : 65);
          expect(h.sleepLabel, '15 minutes');
          expect((await h.store.readCheckpoint())!['index'], 2);
          await h.updateCount(null);
          expect(h.pass, 3);
          expect(h.position.inMilliseconds, 750);
          expect(h.playing, !paused);
          expect(player.mode, LoopMode.all);
          await index(gap == 0 ? 3 : 5);
          if (gap != 0) await index(6);
          expect(h.pass, 4);
        },
      );
    }
  }
  for (final gap in [0, 2000]) {
    test(
      'Continuous play 8 to total 25 finishes 25 without reload, gap=$gap',
      () async {
        await h.loadAndStart(passage(count: null, gap: gap));
        for (var i = 1; i < 8; i++) {
          if (gap == 0) {
            await index(i % 2);
          } else {
            await index(1);
            await index(0);
          }
        }
        expect(h.pass, 8);
        player.position = const Duration(milliseconds: 1200);
        final source = player.audioSources[player.currentIndex!];
        final loads = player.loads, pauses = player.pauses;
        await h.updateCount(25);
        expect(h.pass, 8);
        expect(h.position.inMilliseconds, 1200);
        expect(h.playing, true);
        expect(player.loads, loads);
        expect(player.pauses, pauses);
        expect(player.audioSources[player.currentIndex!], same(source));
        final last = player.audioSources.length - 1;
        await index(last);
        expect(h.pass, 25);
        expect(h.inGap, false);
        player.processingState = ProcessingState.completed;
        player.events.add(PlaybackEvent(currentIndex: last));
        await Future<void>.delayed(Duration.zero);
        await h.pause();
        expect(h.completed, true);
        expect(h.playing, false);
        expect(h.pass, 25);
        expect(player.loads, loads);
      },
    );
    test(
      'reached new total retains current play until native end, gap=$gap',
      () async {
        await h.loadAndStart(passage(gap: gap));
        await index(gap == 0 ? 2 : 4);
        player.position = const Duration(milliseconds: 900);
        final source = player.audioSources[player.currentIndex!];
        final loads = player.loads;
        await h.updateCount(1);
        expect(h.pass, 3);
        expect(h.spec!.playCount, 1);
        expect(h.playing, true);
        expect(h.completed, false);
        expect(h.position.inMilliseconds, 900);
        expect(player.audioSources.last, same(source));
        expect(player.loads, loads);
        expect((await h.store.readCheckpoint())!['index'], 2);
        await h.updateCount(10);
        expect(h.pass, 3);
        expect(h.playing, true);
        expect(player.audioSources.length, gap == 0 ? 10 : 19);
      },
    );
  }
  test('count during paused gap preserves the native silence and stops at a reached limit', () async {
    await h.loadAndStart(passage(gap: 2000));
    await index(3);
    player.position = const Duration(milliseconds: 400);
    await h.pause();
    final silence = player.audioSources[3], loads = player.loads;
    await h.updateCount(33);
    expect(h.pass, 2);
    expect(h.inGap, true);
    expect(player.position.inMilliseconds, 400);
    expect(player.audioSources[3], same(silence));
    expect(h.playing, false);
    await h.updateCount(1);
    expect(h.completed, true);
    expect(h.pass, 2);
    expect(player.loads, loads);
  });
  test('count edit preserves armed finish-pass behavior', () async {
    await h.loadAndStart(passage());
    await index(2);
    await h.setSleepTimer(null, afterPass: true);
    final loads = player.loads;
    await h.updateCount(null);
    expect(player.mode, LoopMode.off);
    expect(player.audioSources.length, 3);
    expect(h.pass, 3);
    expect(h.sleepLabel, 'Finishing this pass');
    expect(player.loads, loads);
  });
}
