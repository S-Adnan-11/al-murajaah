import 'dart:async';
import 'dart:io';

import 'package:al_murajaah/core/audio/prototype_handler.dart';
import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

import 'stage4_offline_recovery_test.dart' show RecoveryPlayer, until;

class V19Player extends RecoveryPlayer {
  int inspections = 0;
  bool failPreparation = false;
  Future<void> _preparationFailure() async {
    if (!failPreparation) return;
    final error = PlayerException(0, 'Offline preparation fixture', null);
    errors.add(error);
    await Future<void>.delayed(Duration.zero);
    throw error;
  }

  @override
  Future<Duration?> setAudioSources(
    List<AudioSource> sources, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
    ShuffleOrder? shuffleOrder,
  }) async {
    await _preparationFailure();
    return super.setAudioSources(
      sources,
      preload: preload,
      initialIndex: initialIndex,
      initialPosition: initialPosition,
      shuffleOrder: shuffleOrder,
    );
  }

  @override
  Future<Duration?> setAudioSource(
    AudioSource source, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    inspections++;
    await _preparationFailure();
    final duration = await super.setAudioSource(
      source,
      preload: preload,
      initialIndex: initialIndex,
      initialPosition: initialPosition,
    );
    processingState = ProcessingState.ready;
    return duration;
  }

  void finish({bool twice = false}) {
    position = const Duration(seconds: 10);
    processingState = ProcessingState.completed;
    events.add(playbackEvent);
    if (twice) events.add(playbackEvent);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late V19Player player;
  late PrototypeHandler h;
  Completer<SessionSpec?>? nextGate;
  Completer<File?>? localGate;
  int nextCalls = 0, resolutions = 0;
  SessionSpec full(int index, {int? count = 1, double speed = 1}) =>
      SessionSpec(
        assetId: samples[index].id,
        durationMs: 10000,
        playCount: count,
        speed: speed,
      );
  setUp(() async {
    root = await Directory.systemTemp.createTemp('v19-playback');
    player = V19Player();
    nextGate = null;
    localGate = null;
    nextCalls = resolutions = 0;
    h = PrototypeHandler(
      PrototypeStore(root),
      player: player,
      localResolver: (_) async {
        resolutions++;
        return await localGate?.future;
      },
      nextSession: (current) {
        nextCalls++;
        if (nextGate != null) return nextGate!.future;
        final index = samples.indexWhere((a) => a.id == current.assetId);
        return index == samples.length - 1
            ? null
            : full(index + 1, speed: current.speed);
      },
    );
  });
  tearDown(() async {
    await h.dispose();
    await root.delete(recursive: true);
  });

  for (final warm in [false, true]) {
    test(
      'failed ${warm ? 'warm queue' : 'cold inspection'} next retains recovery identity without retry',
      () async {
        await h.loadAndStart(full(0));
        if (warm) h.durations[samples[1].id] = 10000;
        player.failPreparation = true;
        player.finish();
        await until(
          () =>
              h.lastError?.startsWith('Could not start the next surah') ==
                  true &&
              !h.loading,
        );
        expect(h.displaySession!.assetId, samples[1].id);
        expect(h.spec!.isPassage, false);
        expect(h.mediaItem.value!.title, samples[1].name);
        expect(h.playRequested, false);
        expect(h.playbackState.value.playing, false);
        expect(h.position, Duration.zero);
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(nextCalls, 1);
        expect(player.plays, 1);
      },
    );
  }

  test('one natural full pass advances exactly once, preserving speed and deadline', () async {
    await h.loadAndStart(full(0, speed: 1.85));
    await h.setSleepTimer(const Duration(minutes: 15));
    final deadline = h.diagnostics['sleepDeadlineUtc'];
    player.finish(twice: true);
    await until(() => h.spec?.assetId == samples[1].id && h.playing);
    expect(nextCalls, 1);
    expect(h.spec!.isPassage, false);
    expect(h.spec!.startMs, 0);
    expect(h.spec!.playCount, 1);
    expect(h.pass, 1);
    expect(h.spec!.speed, 1.85);
    expect(h.diagnostics['sleepDeadlineUtc'], deadline);
    expect(h.mediaItem.value!.title, samples[1].name);
  });
  for (final kind in ['finite', 'continuous', 'passage', 'last', 'sleep']) {
    test('$kind completion never advances', () async {
      var request = full(
        kind == 'last' ? samples.length - 1 : 0,
        count: kind == 'finite'
            ? 5
            : kind == 'continuous'
            ? null
            : 1,
      );
      if (kind == 'passage') {
        request = SessionSpec(
          assetId: request.assetId,
          durationMs: 10000,
          startMs: 2000,
          endMs: 5000,
          isPassage: true,
        );
      }
      await h.loadAndStart(request);
      if (kind == 'sleep') await h.setSleepTimer(null, afterPass: true);
      if (kind == 'finite') player.index(4);
      player.finish(twice: true);
      await until(() => h.completed && !player.playing);
      if (kind == 'last') await until(() => nextCalls == 1);
      expect(h.spec!.assetId, request.assetId);
      expect(nextCalls, kind == 'last' ? 1 : 0);
      expect(player.plays, 1);
    });
  }
  test(
    'sequential count change preserves pass/position, then five stops',
    () async {
      await h.loadAndStart(full(0));
      player.position = const Duration(seconds: 4);
      final loads = player.loads;
      await h.updateCount(5);
      expect(player.loads, loads);
      expect(h.position.inSeconds, 4);
      expect(h.pass, 1);
      player.index(4);
      player.finish();
      await until(() => h.completed && !player.playing);
      expect(nextCalls, 0);
      expect(h.pass, 5);
    },
  );
  test(
    'reducing a later full pass to one finishes it, then restores sequence',
    () async {
      await h.loadAndStart(full(0, count: 5));
      player.index(2);
      await Future<void>.delayed(Duration.zero);
      player.position = const Duration(seconds: 4);
      await h.updateCount(1);
      expect(h.pass, 3);
      expect(h.position.inSeconds, 4);
      player.finish();
      await until(() => h.spec?.assetId == samples[1].id && h.playing);
      expect(nextCalls, 1);
      expect(h.pass, 1);
    },
  );
  for (final action in ['pause', 'stop', 'count', 'sleep', 'new-play']) {
    test('$action cancels a pending automatic transition', () async {
      await h.loadAndStart(full(0));
      nextGate = Completer<SessionSpec?>();
      player.finish(twice: true);
      await until(() => nextCalls == 1);
      if (action == 'pause') await h.pause();
      if (action == 'stop') await h.stop();
      if (action == 'count') await h.updateCount(5);
      if (action == 'sleep') {
        await h.setSleepTimer(const Duration(milliseconds: 10));
        await Future<void>.delayed(const Duration(milliseconds: 30));
      }
      if (action == 'new-play') await h.loadAndStart(full(2));
      nextGate!.complete(full(1));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(h.spec!.assetId, samples[action == 'new-play' ? 2 : 0].id);
      expect(player.plays, action == 'new-play' ? 2 : 1);
    });
  }
  test(
    'Stop while next source verifies prevents a delayed native start',
    () async {
      await h.loadAndStart(full(0));
      localGate = Completer<File?>();
      player.finish();
      await until(() => resolutions == 2);
      expect(h.spec, isNull);
      expect(h.displaySession!.assetId, samples[1].id);
      expect(h.loading, true);
      expect(h.playRequested, true);
      expect(h.position, Duration.zero);
      expect(h.mediaItem.value!.title, samples[1].name);
      final stopping = h.stop();
      localGate!.complete(null);
      await stopping;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(player.plays, 1);
      expect(h.playRequested, false);
      expect(h.displaySession, isNull);
    },
  );
  test('warm explicit starts inspect duration once and resolve source once per start', () async {
    await h.loadAndStart(full(0));
    expect(player.inspections, 1);
    expect(resolutions, 1);
    await h.loadAndStart(full(0));
    expect(player.inspections, 1);
    expect(resolutions, 2);
  });
  test(
    'delayed duplicate completion after an end seek cannot auto-next',
    () async {
      await h.loadAndStart(full(0));
      await h.seek(const Duration(seconds: 10));
      player.finish(twice: true);
      await until(() => h.completed && !player.playing);
      expect(nextCalls, 0);
      expect(h.pass, 1);
      expect(h.spec!.assetId, samples.first.id);
    },
  );
  test('local sources bypass streaming eligibility for explicit and automatic starts', () async {
    await h.dispose();
    final file = await File('${root.path}/verified.mp3')
        .writeAsBytes([1, 2, 3]);
    h = PrototypeHandler(
      PrototypeStore(root),
      player: player = V19Player(),
      localResolver: (_) async => file,
      streamAllowed: (_) =>
          throw StateError('Network policy must not be consulted'),
      nextSession: (_) => full(1),
    );
    await h.loadAndStart(full(0));
    expect(h.usingLocal, true);
    expect(h.diagnostics['sourceUri'], file.uri.toString());
    player.finish();
    await until(() => h.spec?.assetId == samples[1].id && h.playing);
    expect(h.usingLocal, true);
    expect(h.diagnostics['sourceUri'], file.uri.toString());
  });
  test('system buffering and repeat gaps retain Pause intent and freeze scoped position', () async {
    await h.loadAndStart(
      SessionSpec(
        assetId: samples.first.id,
        durationMs: 10000,
        startMs: 1000,
        endMs: 4000,
        isPassage: true,
        playCount: null,
        gapMs: 2000,
      ),
    );
    player.position = const Duration(seconds: 1);
    player.processingState = ProcessingState.buffering;
    player.events.add(player.playbackEvent);
    await Future<void>.delayed(Duration.zero);
    expect(h.progressing, false);
    expect(h.playbackState.value.playing, true);
    expect(
      h.playbackState.value.processingState,
      AudioProcessingState.buffering,
    );
    expect(h.playbackState.value.controls[1].action, MediaAction.pause);
    final position = h.playbackState.value.position;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(h.playbackState.value.position, position);
    player.processingState = ProcessingState.ready;
    player.index(1);
    player.events.add(player.playbackEvent);
    await Future<void>.delayed(Duration.zero);
    expect(h.inGap, true);
    expect(h.progressing, false);
    expect(h.playbackState.value.playing, true);
    expect(h.playbackState.value.processingState, AudioProcessingState.ready);
    expect(h.playbackState.value.speed, 0);
    expect(h.playbackState.value.updatePosition.inMilliseconds, 3000);
    await h.pause();
    player.events.add(player.playbackEvent);
    await Future<void>.delayed(Duration.zero);
    expect(h.playbackState.value.playing, false);
    expect(h.playbackState.value.controls[1].action, MediaAction.play);
  });
  test('system seeks use relative scope, clamp, preserve paused intent and title-only rename', () async {
    final passage = SessionSpec(
      assetId: samples.first.id,
      durationMs: 10000,
      startMs: 2000,
      endMs: 5000,
      isPassage: true,
      passageId: 'stable-save',
      passageTitle: 'Revision',
    );
    await h.loadAndStart(passage);
    await h.pause();
    await h.fastForward();
    expect(player.position.inMilliseconds, 3000);
    await h.rewind();
    expect(player.position, Duration.zero);
    expect(player.plays, 1);
    expect(h.pass, 1);
    final loads = player.loads;
    final identity = h.mediaItem.value!.id;
    await h.applySavedPassage(passage.withPassage('stable-save', 'Renamed'));
    expect(player.loads, loads);
    expect(h.mediaItem.value!.title, 'Renamed');
    expect(h.mediaItem.value!.artist, contains(samples.first.name));
    expect(h.mediaItem.value!.id, identity);
    expect(h.mediaItem.value!.duration!.inMilliseconds, 3000);
    expect(h.playbackState.value.controls.map((c) => c.action), [
      MediaAction.rewind,
      MediaAction.play,
      MediaAction.fastForward,
      MediaAction.stop,
    ]);
    expect(
      h.playbackState.value.controls[0].androidIcon,
      'drawable/ic_replay_10',
    );
    expect(h.playbackState.value.controls[0].label, 'Back 10 seconds');
    expect(
      h.playbackState.value.controls[2].androidIcon,
      'drawable/ic_forward_10',
    );
    expect(h.playbackState.value.controls[2].label, 'Forward 10 seconds');
  });
  test('high-speed changes keep recitation source, pass and paused intent even with gaps', () async {
    await h.loadAndStart(
      SessionSpec(
        assetId: samples.first.id,
        durationMs: 10000,
        startMs: 1000,
        endMs: 4000,
        isPassage: true,
        playCount: 5,
        gapMs: 2000,
      ),
    );
    player.index(2);
    await Future<void>.delayed(Duration.zero);
    player.position = const Duration(seconds: 1);
    await h.pause();
    final source = player.audioSources[2], loads = player.loads;
    for (final speed in [1.5, 1.85, 2.0, 2.2, 1.0]) {
      await h.setSpeed(speed);
      expect(player.audioSources[2], same(source));
      expect(player.loads, loads);
      expect(h.pass, 2);
      expect(h.position.inSeconds, 1);
      expect(h.playing, false);
      expect(player.pitch, 1);
      expect(h.mediaItem.value!.duration!.inSeconds, 3);
    }
  });
}
