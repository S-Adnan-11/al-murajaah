import 'dart:async';
import 'dart:io';

import 'package:al_murajaah/core/audio/prototype_handler.dart';
import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

/// Real handler, held source loading and explicit native-event fixtures.
/// This tests intent/order and queue construction, not audible playback.
class HeldPlayer implements AudioPlayer {
  final events = StreamController<PlaybackEvent>.broadcast();
  final indices = StreamController<int?>.broadcast();
  final errors = StreamController<PlayerException>.broadcast();
  @override
  Stream<PlaybackEvent> get playbackEventStream => events.stream;
  @override
  Stream<int?> get currentIndexStream => indices.stream;
  @override
  Stream<PlayerException> get errorStream => errors.stream;
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  PlaybackEvent playbackEvent = PlaybackEvent();
  @override
  Duration position = Duration.zero;
  @override
  Duration bufferedPosition = Duration.zero;
  @override
  ProcessingState processingState = ProcessingState.ready;
  @override
  bool playing = false;
  @override
  double speed = 1, pitch = 1, volume = 1;
  @override
  int? androidAudioSessionId;
  @override
  int? currentIndex = 0;
  @override
  List<AudioSource> audioSources = [];
  Completer<void>? loading;
  LoopMode? mode;
  int plays = 0;
  int loads = 0, pauses = 0;
  Object? loadError;
  @override
  Future<void> pause() async {
    pauses++;
    playing = false;
  }

  @override
  Future<void> stop() async {
    playing = false;
  }

  @override
  Future<void> play() async {
    plays++;
    playing = true;
  }

  @override
  Future<void> setLoopMode(LoopMode value) async {
    mode = value;
  }

  @override
  Future<void> setSpeed(double value) async {
    speed = value;
  }

  @override
  Future<Duration?> setAudioSource(
    AudioSource source, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    await loading?.future;
    audioSources = [source];
    return const Duration(seconds: 10);
  }

  @override
  Future<Duration?> setAudioSources(
    List<AudioSource> sources, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
    ShuffleOrder? shuffleOrder,
  }) async {
    loads++;
    if (loadError != null) throw loadError!;
    await loading?.future;
    audioSources = sources;
    currentIndex = initialIndex ?? 0;
    playbackEvent = PlaybackEvent(currentIndex: currentIndex);
    position = initialPosition ?? Duration.zero;
    return const Duration(seconds: 10);
  }

  @override
  Future<void> removeAudioSourceRange(int start, int end) async {
    audioSources.removeRange(start, end);
  }

  @override
  Future<void> addAudioSources(List<AudioSource> sources) async {
    audioSources.addAll(sources);
  }

  @override
  Future<void> insertAudioSource(int index, AudioSource source) async {
    audioSources.insert(index, source);
  }

  @override
  Future<void> removeAudioSourceAt(int index) async {
    audioSources.removeAt(index);
  }

  void index(int i) {
    currentIndex = i;
    playbackEvent = PlaybackEvent(currentIndex: i);
    indices.add(i);
  }

  @override
  Future<void> dispose() async {
    await events.close();
    await indices.close();
    await errors.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late HeldPlayer player;
  late PrototypeHandler h;
  Completer<File?>? resolverGate;
  int resolutions = 0;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('play-intent');
    player = HeldPlayer();
    resolverGate = null;
    resolutions = 0;
    h = PrototypeHandler(
      PrototypeStore(root),
      player: player,
      localResolver: (_) async {
        resolutions++;
        return await resolverGate?.future;
      },
    );
  });
  tearDown(() async {
    await h.dispose();
    await root.delete(recursive: true);
  });
  SessionSpec full(String id) => SessionSpec(assetId: id, durationMs: 10000);
  test(
    'Pause before replacement resolves retains the original native descriptor',
    () async {
      await h.loadAndStart(full(samples.first.id));
      h.durations[samples.last.id] = 10000;
      resolverGate = Completer<File?>();
      final replacement = h.loadAndStart(full(samples.last.id));
      for (var i = 0; i < 50 && resolutions < 2; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(resolutions, 2);
      expect(h.spec!.assetId, samples.first.id);
      expect(h.diagnostics['sourceUri'], samples.first.url);
      final cancellation = h.pause();
      resolverGate!.complete(null);
      await Future.wait([replacement, cancellation]);
      expect(player.loads, 1);
      expect(h.spec!.assetId, samples.first.id);
      expect(h.diagnostics['sourceUri'], samples.first.url);
      await h.play();
      expect(h.mediaItem.value!.id, samples.first.id);
      expect(
        (player.audioSources.single as UriAudioSource).uri.toString(),
        samples.first.url,
      );
    },
  );
  for (final cancel in ['Pause', 'Stop']) {
    test(
      '$cancel during warm replacement keeps native source and identity paired',
      () async {
        await h.loadAndStart(full(samples.first.id));
        h.durations[samples.last.id] = 10000;
        player.loading = Completer<void>();
        final replacement = h.loadAndStart(full(samples.last.id));
        for (var i = 0; i < 50 && player.loads < 2; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        expect(
          player.loads,
          2,
          reason: 'must cancel inside native preparation',
        );
        final cancellation = cancel == 'Pause' ? h.pause() : h.stop();
        player.loading!.complete();
        await Future.wait([replacement, cancellation]);
        expect(player.plays, 1, reason: 'late preparation cannot autoplay');
        expect(h.playRequested, false);
        expect(h.spec!.assetId, samples.last.id);
        expect(h.mediaItem.value!.id, samples.last.id);
        expect(h.diagnostics['sourceUri'], samples.last.url);
        expect(
          (player.audioSources.single as UriAudioSource).uri.toString(),
          samples.last.url,
        );
        if (cancel == 'Pause') {
          await h.play();
          await h.updateCount(3);
          expect(player.plays, 2);
          expect(h.spec!.assetId, samples.last.id);
          expect(player.audioSources, hasLength(3));
          for (final source in player.audioSources) {
            expect((source as UriAudioSource).uri.toString(), samples.last.url);
          }
        }
      },
    );
    test(
      '$cancel cancels a held explicit load; late completion never plays',
      () async {
        player.loading = Completer<void>();
        final request = h.loadAndStart(full(samples.first.id));
        await Future<void>.delayed(Duration.zero);
        final cancellation = cancel == 'Pause' ? h.pause() : h.stop();
        player.loading!.complete();
        await request;
        await cancellation;
        expect(player.plays, 0);
        expect(h.playing, false);
      },
    );
  }
  test(
    'new explicit request supersedes a held load; only latest plays and labels',
    () async {
      player.loading = Completer<void>();
      final first = h.loadAndStart(full(samples.first.id));
      await Future<void>.delayed(Duration.zero);
      final second = h.loadAndStart(full(samples.last.id));
      player.loading!.complete();
      await Future.wait([first, second]);
      expect(player.plays, 1);
      expect(h.spec!.assetId, samples.last.id);
      expect(h.mediaItem.value!.id, samples.last.id);
    },
  );
  test('finite native gap queue counts only recitations, has no final gap; sleep trims remaining passes', () async {
    await h.inspect(samples.first);
    await h.start(
      SessionSpec(
        assetId: samples.first.id,
        durationMs: 10000,
        startMs: 2000,
        endMs: 5000,
        isPassage: true,
        playCount: 3,
        gapMs: 2000,
      ),
    );
    expect(player.audioSources, hasLength(5));
    player.index(1);
    await Future<void>.delayed(Duration.zero);
    expect(h.inGap, true);
    expect(h.pass, 1);
    expect(h.position.inMilliseconds, 3000);
    player.index(2);
    await Future<void>.delayed(Duration.zero);
    expect(h.pass, 2);
    expect(h.inGap, false);
    await h.setSleepTimer(null, afterPass: true);
    expect(player.audioSources, hasLength(3));
    expect(player.mode, LoopMode.off);
  });
  test('continuous gaps use native playlist loop; zero-gap queue keeps original finite layout', () async {
    await h.inspect(samples.first);
    await h.start(
      SessionSpec(
        assetId: samples.first.id,
        durationMs: 10000,
        startMs: 2000,
        endMs: 5000,
        isPassage: true,
        playCount: null,
        gapMs: 2000,
      ),
    );
    expect(player.audioSources, hasLength(2));
    expect(player.mode, LoopMode.all);
    player.index(1);
    await Future<void>.delayed(Duration.zero);
    player.index(0);
    await Future<void>.delayed(Duration.zero);
    expect(h.pass, 2);
    await h.start(
      SessionSpec(
        assetId: samples.first.id,
        durationMs: 10000,
        startMs: 2000,
        endMs: 5000,
        isPassage: true,
        playCount: 3,
      ),
    );
    expect(player.audioSources, hasLength(3));
    expect(player.mode, LoopMode.off);
  });
  test(
    'late error from superseded loading does not pause the newer request',
    () async {
      player.loading = Completer<void>();
      final first = h.loadAndStart(full(samples.first.id));
      await Future<void>.delayed(Duration.zero);
      final second = h.loadAndStart(full(samples.last.id));
      player.errors.add(PlayerException(1, 'old source load failure', 0));
      await Future<void>.delayed(Duration.zero);
      player.loading!.complete();
      await Future.wait([first, second]);
      expect(h.lastError, isNull);
      expect(h.spec!.assetId, samples.last.id);
      expect(h.playing, true);
      expect(player.plays, 1);
      player.errors.add(PlayerException(1, 'current source failure', 0));
      await Future<void>.delayed(Duration.zero);
      expect(h.lastError, contains('current source failure'));
      expect(h.playing, false);
    },
  );
  test('retired remote bytes cannot be played under an old identity', () async {
    await h.dispose();
    h = PrototypeHandler(
      PrototypeStore(root),
      player: player = HeldPlayer(),
      localResolver: (_) async => null,
      streamAllowed: (_) => false,
    );
    await expectLater(h.loadAndStart(full(samples.first.id)), throwsStateError);
    expect(player.plays, 0);
  });
}
