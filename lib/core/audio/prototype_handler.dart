import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'prototype_store.dart';
import 'diagnostic_export.dart';
import 'sample_catalog.dart';
import 'session_spec.dart';

class PrototypeHandler extends BaseAudioHandler {
  PrototypeHandler(this.store, {AudioPlayer? player})
    : _player = player ?? AudioPlayer(handleInterruptions: false) {
    _subscriptions.add(
      _player.playbackEventStream.listen((_) {
        _publish();
        recordDiagnostic('player-event');
      }),
    );
    _subscriptions.add(
      _player.currentIndexStream.distinct().listen((index) {
        if (!_loading && spec != null && index != null) {
          _event('pass ${spec!.passAtIndex(index)}');
          _persist();
        }
      }),
    );
    _subscriptions.add(
      _player.errorStream.listen((error) {
        _fail(error, 'player');
      }),
    );
  }
  final PrototypeStore store;
  final AudioPlayer _player;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final ValueNotifier<List<String>> events = ValueNotifier([]);
  final ValueNotifier<int> revision = ValueNotifier(0);
  final Map<String, int> durations = {};
  SessionSpec? spec;
  String? lastError;
  bool usingLocal = false;
  bool forceStreaming = false;
  bool _loading = false, _completed = false, _resumeAfterInterruption = false;
  int _generation = 0;
  Future<void> _commands = Future.value();
  Timer? _diagnosticTimer;
  File? _diagnosticFile;
  Future<void> _diagnosticWrites = Future.value();
  final List<Map<String, Object?>> _recentDiagnostics = [];
  int _diagnosticRows = 0;
  String? diagnosticLogError;
  Uri? _sourceUri;
  Duration? _failedPosition;
  int? _failedPass;
  // Errors can leave play intent true. Freeze presentation immediately, before
  // the serialized native pause completes. Normal buffering is already frozen
  // by just_audio's ready-state position gate.
  late final Stream<Duration> _presentationPositionStream = _player
      .positionStream
      .map((_) => position)
      .distinct();
  Stream<Duration> get positionStream => _presentationPositionStream;
  Duration get position => _failedPosition ?? _player.position;
  bool get playing => _player.playing && !_completed && lastError == null;
  bool get completed => _completed;
  int get pass => _failedPass ?? (_player.playbackEvent.currentIndex ?? 0) + 1;

  Map<String, Object?> get diagnostics {
    final event = _player.playbackEvent;
    return {
      'utc': DateTime.now().toUtc().toIso8601String(),
      'asset': spec?.assetId,
      'sourceUri': _sourceUri?.toString(),
      'local': usingLocal,
      'positionMs': position.inMilliseconds,
      'nativeEventPositionMs': event.updatePosition.inMilliseconds,
      'nativeEventUtc': event.updateTime.toUtc().toIso8601String(),
      'bufferedPositionMs': _player.bufferedPosition.inMilliseconds,
      'processingState': _player.processingState.name,
      'playIntent': _player.playing,
      'presentedPlaying': playing,
      'completed': completed,
      'queueIndex': event.currentIndex,
      'pass': pass,
      'speed': _player.speed,
      'pitch': _player.pitch,
      'volume': _player.volume,
      'androidAudioSessionId': _player.androidAudioSessionId,
      'error': lastError,
      'logError': diagnosticLogError,
    };
  }

  /// Observational logging only: this timer never seeks, counts or controls audio.
  void recordDiagnostic(String reason) {
    if (_diagnosticFile == null || _diagnosticRows >= 4000) return;
    final row = {'reason': reason, ...diagnostics};
    _recentDiagnostics.add(row);
    if (_recentDiagnostics.length > 160) _recentDiagnostics.removeAt(0);
    _diagnosticRows++;
    _diagnosticWrites = _diagnosticWrites
        .then((_) async {
          await _diagnosticFile!.writeAsString(
            '${jsonEncode(row)}\n',
            mode: FileMode.append,
            flush: true,
          );
        })
        .catchError((Object error) {
          diagnosticLogError = error.toString();
        });
  }

  String get diagnosticExport => jsonEncode({
    'exportScope':
        'snapshot, last 160 diagnostic rows and last 100 engine events',
    'snapshot': diagnostics,
    'file': _diagnosticFile?.path,
    'recent': _recentDiagnostics,
    'events': events.value,
  });

  Future<DiagnosticFile> exportDiagnosticFile(Map<String, Object?> platform) {
    recordDiagnostic('complete-file-export');
    final metadata = <String, Object?>{
      'utc': DateTime.now().toUtc().toIso8601String(),
      'snapshot': diagnostics,
      'events': List<String>.of(events.value),
      'platform': platform,
      'samplingLimitPerProcess': 4000,
      'rowsScheduledThisProcess': _diagnosticRows,
      'samplingLimitReached': _diagnosticRows >= 4000,
      'logError': diagnosticLogError,
      'scope': 'all files currently stored in this prototype store logs directory; not an audible-duration certificate',
    };
    final rootPath = store.root.path;
    final result = _diagnosticWrites.then(
      (_) => writeDiagnosticFile(rootPath, metadata),
    );
    // Hold subsequent appends behind the snapshot, without blocking playback.
    _diagnosticWrites = result.then<void>((_) {}).catchError((Object error) {
      diagnosticLogError = error.toString();
    });
    return result;
  }

  void _fail(Object error, String origin, {bool pausePlayer = true}) {
    _failedPosition ??= _player.position;
    _failedPass ??= (_player.playbackEvent.currentIndex ?? 0) + 1;
    lastError = error.toString();
    _event('$origin error: $lastError');
    _publish();
    if (pausePlayer) {
      unawaited(
        pause().catchError((Object error) {
          _event('error pause failed: $error');
        }),
      );
    }
  }

  void _event(String message) {
    final line = '${DateTime.now().toUtc().toIso8601String()} $message';
    events.value = [
      ...events.value,
      line,
    ].reversed.take(100).toList().reversed.toList();
    debugPrint('AUDIO_PROOF $line');
    recordDiagnostic(message);
    revision.value++;
  }

  Future<void> _queue(
    Future<void> Function() command, {
    bool pauseOnError = true,
  }) {
    final result = _commands.then((_) => command());
    _commands = result.catchError((Object error) {
      _fail(error, 'command', pausePlayer: pauseOnError);
    });
    return result;
  }

  Future<void> initialize() async {
    final startupClock = Stopwatch()..start();
    final logs = Directory('${store.root.path}/logs');
    await logs.create(recursive: true);
    _diagnosticFile = File(
      '${logs.path}/audio-${DateTime.now().toUtc().microsecondsSinceEpoch}.jsonl',
    );
    recordDiagnostic('initialized');
    _diagnosticTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => recordDiagnostic('sample'),
    );
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    _subscriptions.add(
      session.becomingNoisyEventStream.listen((_) => unawaited(pause())),
    );
    _subscriptions.add(
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          _resumeAfterInterruption = playing;
          unawaited(
            _queue(() async {
              await _player.pause();
              await _persist();
            }),
          );
        } else if (_resumeAfterInterruption &&
            event.type == AudioInterruptionType.pause) {
          _resumeAfterInterruption = false;
          unawaited(play());
        }
      }),
    );
    try {
      recordDiagnostic('startup-checkpoint-read');
      final checkpoint = await store.readCheckpoint();
      if (checkpoint != null) {
        final restored = SessionSpec.fromJson(
          Map<String, dynamic>.from(checkpoint['spec']),
        );
        final asset = assetById(restored.assetId);
        recordDiagnostic('startup-checkpoint-verification');
        final duration = await inspect(asset);
        if (duration != restored.durationMs) {
          throw StateError('Recording duration changed.');
        }
        await start(
          restored,
          autoPlay: false,
          initialIndex: (checkpoint['index'] as int).clamp(
            0,
            (restored.playCount ?? 1) - 1,
          ),
          initialPosition: Duration(
            milliseconds: checkpoint['positionMs'] as int,
          ),
        );
        _event('restored paused checkpoint');
      }
    } catch (error) {
      lastError = 'Checkpoint could not be restored: $error';
      _event(lastError!);
    } finally {
      recordDiagnostic(
        'startup-ready elapsedMs=${startupClock.elapsedMilliseconds}',
      );
    }
  }

  /// Establish duration through the one native player before range validation.
  Future<int> inspect(SampleAsset asset) async {
    final token = ++_generation;
    var durationMs = 0;
    await _queue(() async {
      if (token != _generation) return;
      _loading = true;
      spec = null;
      _completed = false;
      lastError = null;
      _failedPosition = null;
      _failedPass = null;
      try {
        await _player.pause();
        await _player.setLoopMode(LoopMode.off);
        final file = forceStreaming ? null : await store.verifiedFile(asset);
        usingLocal = file != null;
        _sourceUri = file?.uri ?? Uri.parse(asset.url);
        final duration = await _player.setAudioSource(
          AudioSource.uri(_sourceUri!),
        );
        durationMs = duration?.inMilliseconds ?? 0;
        if (durationMs < 1000) throw StateError('Usable duration unavailable.');
        if (token != _generation) return;
        durations[asset.id] = durationMs;
        spec = SessionSpec(assetId: asset.id, durationMs: durationMs);
        _event('loaded ${asset.id} durationMs=$durationMs local=$usingLocal');
      } finally {
        _loading = false;
        _publish();
      }
    });
    return durationMs;
  }

  Future<void> start(
    SessionSpec request, {
    bool autoPlay = true,
    int initialIndex = 0,
    Duration initialPosition = Duration.zero,
  }) {
    final asset = assetById(request.assetId);
    if (durations[asset.id] != request.durationMs) {
      throw StateError('Load and verify the recording duration first.');
    }
    request.passAtIndex(initialIndex);
    final token = ++_generation;
    _resumeAfterInterruption = false;
    return _queue(() async {
      if (token != _generation) return;
      _loading = true;
      _completed = false;
      lastError = null;
      _failedPosition = null;
      _failedPass = null;
      try {
        await _player.pause();
        final file = forceStreaming ? null : await store.verifiedFile(asset);
        if (token != _generation) return;
        usingLocal = file != null;
        final uri = file?.uri ?? Uri.parse(asset.url);
        _sourceUri = uri;
        final sources = List<AudioSource>.generate(
          request.playCount ?? 1,
          (_) => request.isPassage
              ? ClippingAudioSource(
                  child: AudioSource.uri(uri),
                  start: Duration(milliseconds: request.startMs),
                  end: Duration(milliseconds: request.endMs),
                )
              : AudioSource.uri(uri),
        );
        await _player.setLoopMode(
          request.playCount == null ? LoopMode.one : LoopMode.off,
        );
        await _player.setAudioSources(
          sources,
          initialIndex: initialIndex,
          initialPosition: Duration(
            milliseconds: initialPosition.inMilliseconds.clamp(
              0,
              request.lengthMs,
            ),
          ),
        );
        if (token != _generation) return;
        spec = request;
        _event(
          'start ${asset.id} A=${request.startMs} B=${request.endMs} count=${request.playCount ?? 'continuous'} local=$usingLocal',
        );
        await _persist();
      } finally {
        _loading = false;
        _publish();
      }
      if (autoPlay && token == _generation) _beginPlayback();
    });
  }

  void _beginPlayback() {
    unawaited(
      _player.play().catchError((Object error) {
        _fail(error, 'play');
      }),
    );
  }

  Future<void> _persist() async {
    if (spec != null) {
      await store.checkpoint(
        spec!,
        pass - 1,
        position.inMilliseconds.clamp(0, spec!.lengthMs),
      );
    }
  }

  void _publish() {
    if (_loading) return;
    if (_player.processingState == ProcessingState.completed &&
        !_completed &&
        lastError == null) {
      _completed = true;
      _event('completed pass=$pass reason=finite-end');
      // Player event streams are synchronous. Mutating the player in this
      // callback would re-enter its controller; serialize after this event.
      final completedGeneration = _generation;
      unawaited(
        _queue(() async {
          if (completedGeneration != _generation || !_completed) return;
          await _player.pause();
          await _persist();
        }).catchError((Object error) {
          lastError = 'Completion pause failed: $error';
          _event(lastError!);
        }),
      );
    }
    final state = AudioProcessingState.values[_player.processingState.index];
    playbackState.add(
      PlaybackState(
        controls: [
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0],
        processingState: state,
        playing: playing,
        updatePosition: position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.playbackEvent.currentIndex,
      ),
    );
    final current = spec;
    if (current != null) {
      mediaItem.add(
        MediaItem(
          id: current.assetId,
          title: assetById(current.assetId).name,
          artist: 'Muhammad Bukar Zarami • Hafs',
          album: current.isPassage ? 'Passage Loop' : 'Full surah',
          duration: Duration(milliseconds: current.lengthMs),
        ),
      );
    }
    revision.value++;
  }

  @override
  Future<void> play() async {
    if (spec == null) return;
    if (lastError != null) {
      throw StateError(
        'Load the recording again before resuming after an error.',
      );
    }
    if (completed) {
      await start(spec!);
      return;
    }
    await _queue(() async {
      _beginPlayback();
    });
  }

  @override
  Future<void> pause() {
    _resumeAfterInterruption = false;
    return _queue(() async {
      await _player.pause();
      await _persist();
      _event('paused pass=$pass');
    }, pauseOnError: false);
  }

  @override
  Future<void> stop() {
    ++_generation;
    _resumeAfterInterruption = false;
    return _queue(() async {
      await _player.stop();
      await _persist();
      _event('stopped');
    });
  }

  @override
  Future<void> seek(Duration position) => _queue(() async {
    if (spec == null) return;
    await _player.seek(
      Duration(milliseconds: position.inMilliseconds.clamp(0, spec!.lengthMs)),
    );
    await _persist();
  });
  @override
  Future<void> setSpeed(double speed) => _queue(() => _player.setSpeed(speed));
  Future<void> dispose() async {
    _diagnosticTimer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
    await _diagnosticWrites;
    events.dispose();
    revision.dispose();
  }
}
