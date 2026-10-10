import 'dart:async';
import 'dart:io';

import 'package:al_murajaah/core/audio/prototype_handler.dart';
import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

import 'playback_intent_test.dart' show HeldPlayer;

class RecoveryPlayer extends HeldPlayer {
  final seeks = <Duration>[];
  Completer<void>? seeking;
  bool updateSeekEarly = false;

  @override
  Future<Duration?> setAudioSources(
    List<AudioSource> sources, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
    ShuffleOrder? shuffleOrder,
  }) async {
    final duration = await super.setAudioSources(
      sources,
      preload: preload,
      initialIndex: initialIndex,
      initialPosition: initialPosition,
      shuffleOrder: shuffleOrder,
    );
    processingState = ProcessingState.ready;
    return duration;
  }

  @override
  Future<void> seek(Duration? value, {int? index}) async {
    final target = value ?? Duration.zero;
    seeks.add(target);
    if (updateSeekEarly) position = target;
    await seeking?.future;
    if (index != null) this.index(index);
    if (!updateSeekEarly) position = target;
  }

  @override
  Future<void> stop() async {
    await super.stop();
    processingState = ProcessingState.idle;
  }
}

Future<void> until(bool Function() check) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (!check()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('Bounded recovery check timed out');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late RecoveryPlayer player;
  late PrototypeHandler h;
  late StreamController<String> downloads;
  late File file;
  bool available = false;
  Completer<File?>? verification;
  int lookups = 0;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('offline-recovery');
    file = await File('${root.path}/verified.mp3').writeAsBytes([1, 2, 3]);
    player = RecoveryPlayer();
    downloads = StreamController<String>.broadcast();
    available = false;
    verification = null;
    lookups = 0;
    h = PrototypeHandler(
      PrototypeStore(root),
      player: player,
      verifiedDownloads: downloads.stream,
      localResolver: (asset) async {
        lookups++;
        if (asset.id != samples.first.id) return null;
        if (verification != null) return verification!.future;
        return available ? file : null;
      },
    );
  });
  tearDown(() async {
    await h.dispose();
    await downloads.close();
    await root.delete(recursive: true);
  });

  SessionSpec session({bool passage = false, int? count = 5, int gap = 0}) =>
      SessionSpec(
        assetId: samples.first.id,
        durationMs: 10000,
        startMs: passage ? 2000 : 0,
        endMs: passage ? 5000 : 10000,
        isPassage: passage,
        playCount: count,
        gapMs: gap,
        speed: .9,
        passageId: passage ? 'saved-active' : null,
        passageTitle: passage ? 'Active save' : null,
      );
  Future<void> index(int value) async {
    player.index(value);
    await Future<void>.delayed(Duration.zero);
  }

  void error() {
    player.processingState = ProcessingState.idle;
    player.playing = false;
    player.errors.add(
      PlayerException(0, 'Remote source unavailable', player.currentIndex),
    );
  }

  test('healthy stream stays on its source after download; next pass uses only local descriptors', () async {
    await h.loadAndStart(session());
    player.position = const Duration(milliseconds: 1700);
    final loads = player.loads, plays = player.plays, pauses = player.pauses;
    available = true;
    downloads.add(samples.first.id);
    await until(() => h.diagnostics['localCopyReady'] == true);
    expect(h.usingLocal, false);
    expect(player.loads, loads);
    expect(player.plays, plays);
    expect(player.pauses, pauses);
    expect(h.position.inMilliseconds, 1700);
    player.position = const Duration(milliseconds: 80);
    await index(1);
    await until(() => h.usingLocal && h.diagnostics['recovering'] == false);
    expect(h.pass, 2);
    expect(h.position.inMilliseconds, 80);
    expect(
      player.audioSources.whereType<UriAudioSource>().map((s) => s.uri).toSet(),
      {file.uri},
    );
    await index(2);
    expect(h.pass, 3);
    expect(player.loads, loads + 1);
  });

  for (final passage in [false, true]) {
    for (final continuous in [false, true]) {
      test(
        'error recovers exact source/pass/options/deadline: passage=$passage continuous=$continuous',
        () async {
          final request = session(
            passage: passage,
            count: continuous ? null : 5,
            gap: passage ? 2000 : 0,
          );
          await h.loadAndStart(request);
          if (continuous) {
            await index(1);
            await index(0);
            if (passage) {
              await index(1);
              await index(0);
            }
          } else {
            await index(passage ? 4 : 2);
          }
          player.position = const Duration(milliseconds: 1234);
          await h.setSleepTimer(
            const Duration(minutes: 15),
            finishCurrentPass: false,
          );
          final beforePass = h.pass,
              deadline = h.diagnostics['sleepDeadlineUtc'];
          available = true;
          error();
          await until(
            () => h.usingLocal && h.diagnostics['recovering'] == false,
          );
          expect(h.spec!.toJson(), request.toJson());
          expect(h.position.inMilliseconds, 1234);
          expect(h.pass, beforePass);
          expect(h.playing, true);
          expect(h.lastError, isNull);
          expect(h.diagnostics['sourceUri'], file.uri.toString());
          expect(h.diagnostics['speed'], .9);
          expect(h.diagnostics['sleepDeadlineUtc'], deadline);
          expect(h.sleepFinishesPass, false);
          expect(h.mediaItem.value!.album, samples.first.name);
          expect(
            h.playbackState.value.controls[1].action.toString(),
            contains('pause'),
          );
          for (final source in player.audioSources) {
            if (source is ClippingAudioSource) {
              expect(source.child.uri, file.uri);
              expect(source.start!.inMilliseconds, 2000);
              expect(source.end!.inMilliseconds, 5000);
            } else if (source is UriAudioSource) {
              expect(source.uri.scheme, 'file');
            }
          }
          await index(passage ? (continuous ? 1 : 5) : (continuous ? 1 : 3));
          if (passage && continuous) await index(0);
          if (passage && !continuous) await index(6);
          expect(h.pass, beforePass + 1);
        },
      );
    }
  }

  test(
    'paused gap download preserves gap elapsed/pass and remains paused',
    () async {
      await h.loadAndStart(session(passage: true, gap: 2000));
      await index(5);
      player.position = const Duration(milliseconds: 430);
      await h.pause();
      await h.setSleepTimer(const Duration(minutes: 15));
      final deadline = h.diagnostics['sleepDeadlineUtc'];
      available = true;
      downloads.add(samples.first.id);
      await until(() => h.usingLocal && h.diagnostics['recovering'] == false);
      expect(h.inGap, true);
      expect(h.pass, 3);
      expect(player.position.inMilliseconds, 430);
      expect(h.playing, false);
      expect(h.diagnostics['sleepDeadlineUtc'], deadline);
    },
  );

  test(
    'completed progress stays completed and never starts after download',
    () async {
      await h.loadAndStart(session());
      await index(4);
      player.position = const Duration(seconds: 10);
      player.processingState = ProcessingState.completed;
      player.events.add(player.playbackEvent);
      await until(() => h.completed && !player.playing);
      final plays = player.plays;
      available = true;
      downloads.add(samples.first.id);
      await until(() => h.usingLocal && h.diagnostics['recovering'] == false);
      expect(h.completed, true);
      expect(h.pass, 5);
      expect(h.position.inMilliseconds, 10000);
      expect(player.plays, plays);
    },
  );

  test('buffering with verified copy automatically recovers without native error or Play', () async {
    await h.loadAndStart(session(passage: true));
    available = true;
    downloads.add(samples.first.id);
    await until(() => h.diagnostics['localCopyReady'] == true);
    player.position = const Duration(milliseconds: 850);
    player.processingState = ProcessingState.buffering;
    player.events.add(player.playbackEvent);
    await until(() => h.usingLocal && h.diagnostics['recovering'] == false);
    expect(h.position.inMilliseconds, 850);
    expect(h.pass, 1);
    expect(h.playing, true);
  });

  test('unrelated and other-version notifications never inspect or reload active audio', () async {
    await h.loadAndStart(session());
    final count = lookups, loads = player.loads;
    available = true;
    downloads.add(samples.last.id);
    downloads.add(samples.first.id.replaceFirst('-v1', '-v2'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(lookups, count);
    expect(player.loads, loads);
    expect(h.usingLocal, false);
  });

  test('unverified/missing copy cannot recover; original error/pass/source remain truthful', () async {
    await h.loadAndStart(session(passage: true));
    await index(2);
    player.position = const Duration(milliseconds: 1300);
    error();
    await until(() => h.lastError != null && !player.playing);
    expect(h.usingLocal, false);
    expect(h.pass, 3);
    expect(h.position.inMilliseconds, 1300);
    expect(h.diagnostics['sourceUri'], samples.first.url);
  });

  for (final action in ['pause', 'stop', 'seek', 'switch']) {
    test('late verified download cannot override newer $action', () async {
      await h.loadAndStart(session(passage: true));
      player.position = const Duration(milliseconds: 900);
      verification = Completer<File?>();
      final before = lookups;
      downloads.add(samples.first.id);
      await until(() => lookups > before);
      switch (action) {
        case 'pause':
          await h.pause();
        case 'stop':
          await h.stop();
        case 'seek':
          await h.seek(const Duration(milliseconds: 1800));
        case 'switch':
          await h.loadAndStart(
            SessionSpec(assetId: samples.last.id, durationMs: 10000),
          );
      }
      final plays = player.plays,
          position = h.position,
          assetId = h.spec!.assetId;
      verification!.complete(file);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(h.usingLocal, false);
      expect(h.spec!.assetId, assetId);
      expect(h.position, position);
      expect(player.plays, plays);
      expect(h.diagnostics['localCopyReady'], action != 'switch');
      if (action == 'pause' || action == 'stop') expect(h.playing, false);
    });
  }

  test(
    'sleep expiry while recovery verifies does not resume after its deadline',
    () async {
      await h.loadAndStart(session(passage: true));
      await h.setSleepTimer(
        const Duration(milliseconds: 70),
        finishCurrentPass: false,
      );
      verification = Completer<File?>();
      error();
      await until(() => h.diagnostics['recovering'] == true);
      await until(
        () =>
            h.sleepLabel == 'Off' &&
            h.diagnostics['transportPlayIntent'] == false &&
            !player.playing,
      );
      final plays = player.plays;
      verification!.complete(file);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(h.playing, false);
      expect(player.plays, plays);
    },
  );

  for (final action in ['pause', 'stop', 'seek', 'switch']) {
    test('late native recovery load respects newer $action', () async {
      await h.loadAndStart(session(passage: true));
      await index(2);
      player.position = const Duration(milliseconds: 720);
      player.loading = Completer<void>();
      available = true;
      final loads = player.loads;
      error();
      await until(() => player.loads > loads);
      final latest = switch (action) {
        'pause' => h.pause(),
        'stop' => h.stop(),
        'seek' => h.seek(const Duration(milliseconds: 1800)),
        'switch' => h.loadAndStart(
          SessionSpec(assetId: samples.last.id, durationMs: 10000),
        ),
        _ => throw StateError('Unknown action $action'),
      };
      player.loading!.complete();
      await latest;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(h.lastError, isNull);
      if (action == 'pause' || action == 'stop') {
        expect(h.playing, false);
        expect(player.plays, 1);
      } else if (action == 'seek') {
        expect(h.position.inMilliseconds, 1800);
        expect(h.pass, 3);
        expect(h.playing, true);
      } else {
        expect(h.spec!.assetId, samples.last.id);
        expect(h.pass, 1);
        expect(h.playing, true);
        expect(player.plays, 2);
      }
    });
  }

  test('newer seek wins over a held seek completion without restarting or changing pass', () async {
    await h.loadAndStart(session(passage: true));
    await index(2);
    player.seeking = Completer<void>();
    final first = h.seek(const Duration(milliseconds: 2200));
    await until(() => player.seeks.length == 1);
    final latest = h.seek(const Duration(milliseconds: 400));
    player.seeking!.complete();
    await Future.wait([first, latest]);
    expect(h.position.inMilliseconds, 400);
    expect(h.spec!.relativeToSource(400), 2400);
    expect(h.pass, 3);
    expect(h.playing, true);
    expect(
      h.events.value.where((line) => line.contains('seek relativeMs=')),
      hasLength(1),
    );
  });

  test(
    'native source error releases an unresolved seek before local reload',
    () async {
      await h.loadAndStart(session(passage: true));
      await index(2);
      player.seeking = Completer<void>();
      player.updateSeekEarly = true;
      final seek = h.seek(const Duration(milliseconds: 1800));
      await until(() => player.seeks.isNotEmpty);
      available = true;
      error();
      await until(() => h.usingLocal && h.diagnostics['recovering'] == false);
      await seek;
      expect(player.seeking!.isCompleted, false);
      expect(h.position.inMilliseconds, 1800);
      expect(h.pass, 3);
      expect(h.playing, true);
      expect(h.lastError, isNull);
      player.seeking!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(h.position.inMilliseconds, 1800);
    },
  );

  test('seek during error verification recovers its newer target, not the old position', () async {
    await h.loadAndStart(session(passage: true));
    await index(2);
    player.position = const Duration(milliseconds: 700);
    verification = Completer<File?>();
    error();
    await until(() => h.diagnostics['recovering'] == true);
    await h.seek(const Duration(milliseconds: 1800));
    verification!.complete(file);
    await until(() => h.usingLocal && h.diagnostics['recovering'] == false);
    expect(h.position.inMilliseconds, 1800);
    expect(h.pass, 3);
    expect(h.playing, true);
  });

  for (final continuous in [false, true]) {
    test(
      'transport seek from a gap addresses the clip and retains its pass: continuous=$continuous',
      () async {
        await h.loadAndStart(
          session(passage: true, gap: 2000, count: continuous ? null : 5),
        );
        await index(continuous ? 1 : 5);
        final pass = h.pass;
        await h.pause();
        await h.seek(const Duration(milliseconds: 1000));
        await Future<void>.delayed(Duration.zero);
        expect(h.inGap, false);
        expect(h.pass, pass);
        expect(h.position.inMilliseconds, 1000);
        expect(h.spec!.relativeToSource(1000), 3000);
        expect(h.playing, false);
      },
    );
  }
}
