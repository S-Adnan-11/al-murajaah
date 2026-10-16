import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../features/activity/listening_meter.dart';
import '../../features/activity/listening_recorder.dart';

import 'prototype_store.dart';
import 'diagnostic_export.dart';
import 'sample_catalog.dart';
import 'session_spec.dart';

class PrototypeHandler extends BaseAudioHandler {
  PrototypeHandler(
    this.store, {
    AudioPlayer? player,
    SampleAsset Function(String)? assetResolver,
    Future<File?> Function(SampleAsset)? localResolver,
    bool Function(SampleAsset)? streamAllowed,
    Stream<String>? verifiedDownloads,
    this.nextSession,
    this.listeningRecorder,
    this.knownDuration,
  }) : _player = player ?? AudioPlayer(handleInterruptions: false),
       _assetResolver = assetResolver ?? assetById,
       _localResolver = localResolver ?? store.verifiedFile {
    _streamAllowed = streamAllowed ?? (_) => true;
    if (listeningRecorder != null) {
      _subscriptions.add(
        _player.playerStateStream.listen((_) {
          _trackIndex(_player.playbackEvent.currentIndex);
          _observeListening();
        }),
      );
    }
    _subscriptions.add(
      _player.playbackEventStream.listen((_) {
        _trackIndex(_player.playbackEvent.currentIndex);
        _publish();
        _checkLocalBuffering();
        recordDiagnostic('player-event');
      }),
    );
    _subscriptions.add(
      _player.currentIndexStream.distinct().listen((index) {
        if (!_loading && spec != null && index != null) {
          _trackIndex(index);
          _event(inGap ? 'gap after pass $pass' : 'pass $pass');
          _persist();
          if (!inGap && _readyLocalAsset == spec?.assetId) {
            unawaited(_recoverToLocal(_generation));
          }
        }
      }),
    );
    _subscriptions.add(
      _player.errorStream.listen((error) {
        // The native source still belongs to the old serialized operation until
        // its successor actually begins. Its late error must not cancel that
        // successor. Errors for the current source retain the existing guard.
        if (_nativeGeneration != _generation) {
          recordDiagnostic('superseded-source-error ignored: $error');
          return;
        }
        _sourceError(error);
      }),
    );
    if (verifiedDownloads != null) {
      _subscriptions.add(verifiedDownloads.listen(_downloadVerified));
    }
    _subscriptions.add(
      _player.positionStream.listen((value) {
        if (_startClock != null &&
            progressing &&
            value.inMilliseconds > _startPositionMs &&
            !startupStages.containsKey('first-progress')) {
          _startupStage('first-progress');
        }
      }),
    );
  }
  final PrototypeStore store;
  final ListeningRecorder? listeningRecorder;
  final int? Function(String)? knownDuration;
  bool _restoredMetadata = false;
  bool get restoredMetadata => _restoredMetadata;
  final FutureOr<SessionSpec?> Function(SessionSpec)? nextSession;
  bool _transitioning = false;
  Object? _transitionOwner;
  Stopwatch? _startClock;
  int _startPositionMs = 0;
  final Map<String, int> startupStages = {};
  void _startupStage(String stage) {
    final elapsed = _startClock?.elapsedMilliseconds;
    if (elapsed == null) return;
    startupStages[stage] = elapsed;
    recordDiagnostic('playback-start $stage elapsedMs=$elapsed');
  }

  final Stopwatch _listeningClock = Stopwatch()..start();
  Timer? _listeningTimer;

  void _observeListening() {
    final recorder = listeningRecorder;
    final current = spec;
    if (recorder == null || current == null || _disposed) return;
    final now = DateTime.now();
    final active =
        !_loading &&
        !_stopped &&
        !_completed &&
        lastError == null &&
        _failedPosition == null &&
        _seekInterrupted == null &&
        _nativeGeneration == _generation &&
        _wantedPlaying &&
        _player.playing &&
        !inGap &&
        _player.processingState == ProcessingState.ready;
    recorder.observe(
      ListeningSample(
        elapsedMs: _listeningClock.elapsedMilliseconds,
        utcMs: now.toUtc().millisecondsSinceEpoch,
        offsetMinutes: now.timeZoneOffset.inMinutes,
        epoch: _generation,
        pass: pass,
        positionMs: _player.position.inMilliseconds.clamp(0, current.lengthMs),
        lengthMs: current.lengthMs,
        speed: _player.speed,
        active: active,
        inGap: inGap,
      ),
      current.assetId,
      current.passageId,
    );
    // Continue sampling through native repeat gaps so the next pass rebases.
    if (_wantedPlaying &&
        _player.playing &&
        !_loading &&
        !_completed &&
        lastError == null) {
      _listeningTimer ??= Timer.periodic(
        const Duration(seconds: 1),
        (_) => _observeListening(),
      );
    } else {
      _listeningTimer?.cancel();
      _listeningTimer = null;
    }
  }

  void _listeningDiscontinuity() {
    _observeListening();
    listeningRecorder?.rebase();
  }

  final AudioPlayer _player;
  final SampleAsset Function(String) _assetResolver;
  final Future<File?> Function(SampleAsset) _localResolver;
  late final bool Function(SampleAsset) _streamAllowed;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final ValueNotifier<List<String>> events = ValueNotifier([]);
  final ValueNotifier<int> revision = ValueNotifier(0);
  final Map<String, int> durations = {};
  SessionSpec? spec;
  SessionSpec? _preparingSpec;
  Object? _preparingOwner;

  /// Authorized pending identity stays visible and cancellable while the one
  /// native player prepares it. It is never a second playback authority.
  SessionSpec? get displaySession => _preparingSpec ?? spec;
  String? lastError;
  bool usingLocal = false;
  bool forceStreaming = false;
  bool _loading = false, _completed = false, _resumeAfterInterruption = false;
  bool _wantedPlaying = false, _stopped = false, _recovering = false;
  bool _disposed = false;
  Timer? _localBufferTimer;
  File? _readyLocalFile;
  String? _readyLocalAsset;
  int _generation = 0;
  int _nativeGeneration = 0;
  int? _endSeekGeneration;
  Timer? _sleepTimer;
  String sleepLabel = 'Off';
  bool _sleepEnding = false;
  DateTime? _sleepDeadline;
  bool _sleepFinishPass = true, _previewing = false;
  bool get sleepFinishesPass => _sleepFinishPass;
  int _continuousPass = 1, _previousIndex = 0, _passOffset = 0;
  void _trackIndex(int? index) {
    if (_loading || spec == null || index == null || index == _previousIndex) {
      return;
    }
    if (spec!.playCount == null && (spec!.gapMs == 0 || index.isEven)) {
      _continuousPass++;
    }
    _previousIndex = index;
  }

  Future<void> _commands = Future.value();
  Completer<void>? _seekInterrupted;
  Timer? _diagnosticTimer;
  File? _diagnosticFile;
  Future<void> _diagnosticWrites = Future.value();
  final List<Map<String, Object?>> _recentDiagnostics = [];
  int _diagnosticRows = 0;
  String? diagnosticLogError;
  Uri? _sourceUri;
  Duration? _failedPosition;
  int? _failedPass;
  bool? _failedInGap;
  Duration? _failedGapPosition;
  // Errors can leave play intent true. Freeze presentation immediately, before
  // the serialized native pause completes. Normal buffering is already frozen
  // by just_audio's ready-state position gate.
  late final Stream<Duration> _presentationPositionStream = _player
      .positionStream
      .map((_) => position)
      .distinct();
  Stream<Duration> get positionStream => _presentationPositionStream;
  bool get inGap =>
      spec?.gapMs != 0 && spec != null && ((_player.currentIndex ?? 0).isOdd);
  Duration get position => _preparingSpec != null
      ? Duration.zero
      : _failedPosition ??
            (inGap ? Duration(milliseconds: spec!.lengthMs) : _player.position);
  bool get playing =>
      (_player.playing || (_recovering && _wantedPlaying)) &&
      !_completed &&
      lastError == null;
  bool get completed => _completed;
  bool get loading =>
      _preparingSpec != null ||
      _loading ||
      _transitioning ||
      _recovering ||
      _player.processingState == ProcessingState.loading ||
      _player.processingState == ProcessingState.buffering;
  bool get playRequested => _wantedPlaying || _transitioning;
  bool get progressing =>
      playing &&
      !loading &&
      !inGap &&
      !_stopped &&
      _player.processingState == ProcessingState.ready;
  int get pass =>
      _failedPass ??
      (spec?.playCount == null && spec != null
          ? _continuousPass
          : _passOffset +
                (_player.playbackEvent.currentIndex ?? 0) ~/
                    (spec?.gapMs == 0 || spec == null ? 1 : 2) +
                1);

  Map<String, Object?> get diagnostics {
    final event = _player.playbackEvent;
    return {
      'utc': DateTime.now().toUtc().toIso8601String(),
      'asset': spec?.assetId,
      'assetName': spec == null ? null : _assetResolver(spec!.assetId).name,
      'sourceUri': _sourceUri?.toString(),
      'local': usingLocal,
      'localCopyReady':
          _readyLocalAsset == spec?.assetId && _readyLocalFile != null,
      'recovering': _recovering,
      'generation': _generation,
      'nativeGeneration': _nativeGeneration,
      'transportPlayIntent': _wantedPlaying,
      'stopped': _stopped,
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
      'inGap': inGap,
      'sleepTimer': sleepLabel,
      'sleepDeadlineUtc': _sleepDeadline?.toUtc().toIso8601String(),
      'speed': _player.speed,
      'pitch': _player.pitch,
      'volume': _player.volume,
      'androidAudioSessionId': _player.androidAudioSessionId,
      'error': lastError,
      'startupStagesMs': Map<String, int>.of(startupStages),
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
    _failedPass ??= pass;
    lastError = error.toString();
    _event('$origin error: $lastError');
    _publish();
    // An awaited preparation owns its error and recovery identity. Calling the
    // public Pause here would cancel that owner before its catch can run.
    if (pausePlayer && _preparingSpec == null) {
      unawaited(
        pause().catchError((Object error) {
          _event('error pause failed: $error');
        }),
      );
    }
  }

  void _downloadVerified(String assetId) {
    recordDiagnostic('verified download observed asset=$assetId');
    if (_disposed ||
        forceStreaming ||
        _previewing ||
        usingLocal ||
        spec?.assetId != assetId) {
      return;
    }
    final token = _generation;
    unawaited(() async {
      try {
        final file = await _localResolver(_assetResolver(assetId));
        if (_disposed ||
            file == null ||
            spec?.assetId != assetId ||
            usingLocal ||
            _previewing) {
          return;
        }
        _readyLocalAsset = assetId;
        _readyLocalFile = file;
        _event('verified local copy ready asset=$assetId');
        // Readiness is observational and survives a newer transport action for
        // the same exact recording (including download notification focus).
        // The old completion must never apply a source/transport change.
        if (token != _generation) {
          _checkLocalBuffering();
          return;
        }
        if (lastError != null || (!_player.playing && !_stopped && !_loading)) {
          await _recoverToLocal(token);
        } else {
          _checkLocalBuffering();
        }
      } catch (error) {
        if (!_disposed && token == _generation) {
          _event('verified local copy check failed: $error');
        }
      }
    }());
  }

  void _checkLocalBuffering() {
    if (_disposed ||
        usingLocal ||
        _stopped ||
        _recovering ||
        !_wantedPlaying ||
        _readyLocalAsset != spec?.assetId ||
        _player.processingState != ProcessingState.buffering) {
      _localBufferTimer?.cancel();
      _localBufferTimer = null;
      return;
    }
    final token = _generation;
    _localBufferTimer ??= Timer(const Duration(milliseconds: 750), () {
      _localBufferTimer = null;
      if (token == _generation &&
          _player.processingState == ProcessingState.buffering) {
        unawaited(_recoverToLocal(token));
      }
    });
  }

  void _sourceError(Object error) {
    _interruptPendingSeek();
    if (_preparingSpec != null && _loading) {
      // just_audio reports failed preparation both here and through the load
      // Future. Let that Future settle the authorized pending item once.
      recordDiagnostic('preparing-source-error observed: $error');
      return;
    }
    if (usingLocal ||
        forceStreaming ||
        spec == null ||
        _stopped ||
        _previewing) {
      _fail(error, 'player');
      return;
    }
    if (_recovering) {
      recordDiagnostic('recovery-source-error observed: $error');
      return;
    }
    final token = _generation;
    _failedInGap = inGap;
    _failedGapPosition = inGap ? _player.position : null;
    _failedPosition ??= inGap
        ? Duration(milliseconds: spec!.lengthMs)
        : _player.position;
    _failedPass ??= pass;
    recordDiagnostic('source-error checking verified local audio: $error');
    unawaited(() async {
      final recovered = await _recoverToLocal(token);
      if (!recovered && !_disposed && token == _generation) {
        _fail(error, 'player');
      }
    }());
  }

  /// One verified exact-recording replacement, with live progress/intent.
  /// A healthy current stream is retained until a pass boundary or recovery.
  Future<bool> _recoverToLocal(int token) async {
    if (_disposed ||
        token != _generation ||
        _recovering ||
        usingLocal ||
        forceStreaming ||
        _stopped ||
        _previewing ||
        spec == null) {
      return false;
    }
    _recovering = true;
    _publish();
    int? replacementToken;
    try {
      final assetId = spec!.assetId;
      // Revalidate actual retained bytes; a cached readiness signal alone is
      // never permission to use a missing, partial or changed file.
      final file = await _localResolver(_assetResolver(assetId));
      if (_disposed ||
          token != _generation ||
          file == null ||
          spec?.assetId != assetId ||
          _stopped ||
          _previewing) {
        return false;
      }
      // Verification may have taken time. Snapshot now, after the guard, so
      // counts/options/position and the absolute timer are the current values.
      final request = spec!;
      final currentPass = pass;
      final gap = _failedInGap ?? inGap;
      final elapsed = gap ? (_failedGapPosition ?? _player.position) : position;
      final wasCompleted = _completed;
      final resume = _wantedPlaying && !wasCompleted;
      _readyLocalAsset = assetId;
      _readyLocalFile = file;
      _event(
        'local recovery requested asset=$assetId pass=$currentPass positionMs=${elapsed.inMilliseconds} gap=$gap resume=$resume',
      );
      replacementToken = _generation + 1;
      // Android can leave seek's MethodChannel result pending after a source
      // error/buffer stall. Release its serialized wait before replacing the
      // source; generation guards discard that seek's late completion.
      _interruptPendingSeek();
      await _start(
        request,
        autoPlay: resume,
        initialIndex: currentPass - 1,
        initialPosition: elapsed,
        initialInGap: gap,
        preserveSleep: true,
        verifiedLocalSource: file.uri,
      );
      if (_disposed || replacementToken != _generation) return false;
      if (wasCompleted) _completed = true;
      _event('local recovery complete asset=$assetId pass=$pass');
      await _persist();
      return true;
    } catch (error) {
      if (!_disposed &&
          (token == _generation || replacementToken == _generation)) {
        _event('local recovery failed: $error');
      }
      return false;
    } finally {
      if (!_disposed &&
          (token == _generation || replacementToken == _generation)) {
        _recovering = false;
        _publish();
      }
    }
  }

  void _event(String message) {
    _syncDiagnosticSampling();
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
    int? generation,
  }) {
    final result = _commands.then((_) => command());
    _commands = result.catchError((Object error) {
      if (!_disposed && (generation == null || generation == _generation)) {
        _fail(error, 'command', pausePlayer: pauseOnError);
      }
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
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    _subscriptions.add(
      session.becomingNoisyEventStream.listen((_) => unawaited(pause())),
    );
    _subscriptions.add(
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          _listeningDiscontinuity();
          _resumeAfterInterruption = playing;
          _wantedPlaying = false;
          _recovering = false;
          ++_generation;
          if (!_loading) _nativeGeneration = _generation;
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
        _assetResolver(restored.assetId); // Must still be a retained identity.
        final duration = knownDuration?.call(restored.assetId);
        // Decoder duration may include MP3 encoder padding. Exact retained
        // bytes/identity stay authoritative; Play verifies native duration.
        if (duration != null && (duration - restored.durationMs).abs() > 250) {
          throw StateError('Recording duration changed.');
        }
        final index = checkpoint['index'] as int;
        final positionMs = checkpoint['positionMs'] as int;
        if (index < 0 || positionMs < 0 || positionMs > restored.lengthMs) {
          throw const FormatException('Invalid retained playback position.');
        }
        spec = restored;
        _failedPosition = Duration(milliseconds: positionMs);
        _failedPass = index + 1;
        _restoredMetadata = true;
        _wantedPlaying = false;
        _event('restored paused metadata; source deferred until Play');
        _publish();
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
    _listeningDiscontinuity();
    final token = ++_generation;
    _wantedPlaying = false;
    _recovering = false;
    var durationMs = 0;
    await _queue(() async {
      if (token != _generation) return;
      _loading = true;
      _nativeGeneration = token;
      spec = null;
      _completed = false;
      lastError = null;
      _failedPosition = null;
      _failedPass = null;
      _failedInGap = null;
      _failedGapPosition = null;
      try {
        await _player.pause();
        await _player.setLoopMode(LoopMode.off);
        final file = forceStreaming ? null : await _localResolver(asset);
        if (token != _generation) return;
        _startupStage('source-resolved');
        usingLocal = file != null;
        _sourceUri = file?.uri ?? Uri.parse(asset.url);
        if (file == null && !_streamAllowed(asset)) {
          throw StateError(
            'This recording was replaced. Original verified offline audio is required; saved timestamps need review.',
          );
        }
        final duration = await _player.setAudioSource(
          AudioSource.uri(_sourceUri!),
        );
        durationMs = duration?.inMilliseconds ?? 0;
        if (durationMs < 1000) throw StateError('Usable duration unavailable.');
        if (token != _generation) return;
        durations[asset.id] = durationMs;
        _startupStage('duration-prepared');
        spec = SessionSpec(assetId: asset.id, durationMs: durationMs);
        _restoredMetadata = false;
        _event('loaded ${asset.id} durationMs=$durationMs local=$usingLocal');
      } finally {
        _loading = false;
        _publish();
      }
    }, generation: token);
    return durationMs;
  }

  Future<void> start(
    SessionSpec request, {
    bool autoPlay = true,
    int initialIndex = 0,
    Duration initialPosition = Duration.zero,
  }) => _start(
    request,
    autoPlay: autoPlay,
    initialIndex: initialIndex,
    initialPosition: initialPosition,
  );

  Future<void> _start(
    SessionSpec request, {
    bool autoPlay = true,
    int initialIndex = 0,
    Duration initialPosition = Duration.zero,
    bool initialInGap = false,
    bool preserveSleep = false,
    bool reuseSource = false,
    Uri? verifiedLocalSource,
  }) {
    final asset = _assetResolver(request.assetId);
    if (durations[asset.id] != request.durationMs) {
      throw StateError('Load and verify the recording duration first.');
    }
    if (initialIndex < 0) throw RangeError('Negative pass index');
    _listeningDiscontinuity();
    final token = ++_generation;
    _wantedPlaying = autoPlay;
    _stopped = false;
    _recovering = verifiedLocalSource != null;
    _localBufferTimer?.cancel();
    _localBufferTimer = null;
    _resumeAfterInterruption = false;
    return _queue(() async {
      if (token != _generation) return;
      _loading = true;
      _nativeGeneration = token;
      _startPositionMs = initialPosition.inMilliseconds;
      _completed = false;
      lastError = null;
      _failedPosition = null;
      _failedPass = null;
      _failedInGap = null;
      _failedGapPosition = null;
      try {
        await _player.pause();
        var preparedSource = _sourceUri;
        var preparedLocal = usingLocal;
        if (verifiedLocalSource != null) {
          preparedSource = verifiedLocalSource;
          preparedLocal = true;
        } else if (!reuseSource ||
            _sourceUri == null ||
            spec?.assetId != asset.id) {
          final file = forceStreaming ? null : await _localResolver(asset);
          _startupStage('source-resolved');
          if (token != _generation) return;
          if (file == null && !_streamAllowed(asset)) {
            throw StateError(
              'Replaced recording cannot stream under its old identity.',
            );
          }
          preparedLocal = file != null;
          preparedSource = file?.uri ?? Uri.parse(asset.url);
        }
        AudioSource recitation() =>
            _recitation(request, source: preparedSource!);
        final sources = <AudioSource>[];
        final gap = request.gapMs == 0
            ? null
            : await _silence(request.gapMs, speed: request.speed);
        if (token != _generation) return;
        final total = request.playCount == null
            ? (gap == null ? 2 : 1)
            : (request.playCount! > initialIndex
                  ? request.playCount!
                  : initialIndex + 1);
        for (var i = 0; i < total; i++) {
          sources.add(recitation());
          if (gap != null && (request.playCount == null || i + 1 < total)) {
            sources.add(AudioSource.uri(gap));
          }
        }
        if (!preserveSleep) {
          _sleepTimer?.cancel();
          _sleepDeadline = null;
          sleepLabel = 'Off';
          _sleepEnding = false;
        }
        _continuousPass = initialIndex + 1;
        _passOffset = 0;
        final nativeIndex = request.playCount == null
            ? (initialInGap ? 1 : 0)
            : request.gapMs == 0
            ? initialIndex
            : initialIndex * 2 + (initialInGap ? 1 : 0);
        _previousIndex = nativeIndex;
        if (_sleepEnding) sources.removeRange(nativeIndex + 1, sources.length);
        // Native preparation cannot be undone mid-call. Bind its identity and
        // descriptor together before yielding; a queued Pause/Stop still wins
        // autoplay, but a later Resume must describe the source actually loaded.
        spec = request;
        _restoredMetadata = false;
        _sourceUri = preparedSource;
        usingLocal = preparedLocal;
        await _player.setSpeed(request.speed);
        await _player.setLoopMode(
          request.playCount == null && !_sleepEnding
              ? LoopMode.all
              : LoopMode.off,
        );
        await _player.setAudioSources(
          sources,
          initialIndex: nativeIndex,
          initialPosition: Duration(
            milliseconds: initialPosition.inMilliseconds.clamp(
              0,
              initialInGap
                  ? (request.gapMs * request.speed).round()
                  : request.lengthMs,
            ),
          ),
        );
        if (token != _generation) return;
        _startupStage('queue-prepared');
        _event(
          'start ${asset.id} A=${request.startMs} B=${request.endMs} count=${request.playCount ?? 'continuous'} local=$usingLocal',
        );
        await _persist();
      } finally {
        _loading = false;
        _publish();
      }
      if (autoPlay &&
          token == _generation &&
          !_stopped &&
          !(_sleepDeadline?.isBefore(DateTime.now()) ?? false)) {
        _beginPlayback();
      }
    }, generation: token);
  }

  AudioSource _recitation(SessionSpec request, {Uri? source}) =>
      request.isPassage
      ? ClippingAudioSource(
          child: AudioSource.uri(source ?? _sourceUri!),
          start: Duration(milliseconds: request.startMs),
          end: Duration(milliseconds: request.endMs),
        )
      : AudioSource.uri(source ?? _sourceUri!);

  /// Edit only the future native playlist. The current source, position,
  /// transport intent, timer and number of traversals remain authoritative.
  Future<void> updateCount(int? count) {
    spec?.withCount(count);
    if (count != 1 && _transitioning) {
      _transitioning = false;
      _transitionOwner = null;
    }
    final token = _generation;
    return _queue(() async {
      final current = spec;
      if (token != _generation || current == null) return;
      final request = current.withCount(count);
      if (count == current.playCount) return;
      if (_completed || _player.processingState == ProcessingState.idle) {
        spec = request;
        await _persist();
        _publish();
        return;
      }
      final gap = current.gapMs == 0
          ? null
          : await _silence(current.gapMs, speed: current.speed);
      if (token != _generation) return;
      final stride = gap == null ? 1 : 2;
      int targetLength() {
        final index = _player.currentIndex ?? 0;
        if (_sleepEnding) return index + 1;
        if (count == null) {
          final length = _player.audioSources.length;
          return gap == null
              ? (length < 2 ? 2 : length)
              : (length.isOdd ? length + 1 : length);
        }
        final remaining = (count - pass).clamp(0, 999);
        return index ~/ stride * stride + 1 + remaining * stride;
      }

      final tail = <AudioSource>[];
      for (var i = _player.audioSources.length; i < targetLength(); i++) {
        tail.add(
          gap != null && i.isOdd ? AudioSource.uri(gap) : _recitation(request),
        );
      }
      if (tail.isNotEmpty) await _player.addAudioSources(tail);
      if (token != _generation) return;
      await _player.setLoopMode(
        count == null && !_sleepEnding ? LoopMode.all : LoopMode.off,
      );
      if (token != _generation) return;
      final length = targetLength();
      if (length < _player.audioSources.length) {
        // A reached limit during a gap stops before the next recitation.
        final start = length > (_player.currentIndex ?? 0)
            ? length
            : (_player.currentIndex ?? 0) + 1;
        if (start < _player.audioSources.length) {
          await _player.removeAudioSourceRange(
            start,
            _player.audioSources.length,
          );
        }
      }
      if (token != _generation) return;
      final played = pass;
      _continuousPass = played;
      _passOffset = played - 1 - (_player.currentIndex ?? 0) ~/ stride;
      spec = request;
      if (count != null && count <= played && inGap) {
        await _player.pause();
        _completed = true;
      }
      _event(
        'count changed total=${count ?? 'continuous'} currentPass=$played',
      );
      await _persist();
      _publish();
    }, generation: token);
  }

  /// Save updates only this exact active passage. just_audio's clip bounds are
  /// immutable: boundary changes require replacing its native clip playlist.
  /// Carry source position, pass and transport intent through that replacement.
  Future<void> applySavedPassage(SessionSpec revised) async {
    final current = spec;
    if (current == null || !current.sameItem(revised)) return;
    final wasCompleted = _completed;
    if (current.startMs != revised.startMs ||
        current.endMs != revised.endMs ||
        current.gapMs != revised.gapMs) {
      if (_player.processingState == ProcessingState.idle) {
        spec = revised;
        await _persist();
        _publish();
        return;
      }
      final wasGap = inGap;
      final sourcePosition = current.relativeToSource(position.inMilliseconds);
      final inside =
          sourcePosition >= revised.startMs && sourcePosition < revised.endMs;
      final elapsed = wasGap
          ? _player.position
          : Duration(
              milliseconds: inside ? sourcePosition - revised.startMs : 0,
            );
      // Apply the total separately so a reached limit also retains progress,
      // finishing the current recitation (or stopping before the next in a gap).
      await _start(
        revised.withCount(current.playCount),
        autoPlay: playing,
        initialIndex: pass - 1,
        initialPosition: elapsed,
        initialInGap: wasGap && revised.gapMs > 0,
        preserveSleep: true,
        reuseSource: true,
      );
    }
    if (spec?.sameItem(revised) != true) return;
    await updateCount(revised.playCount);
    await updateOptions(speed: revised.speed, gapMs: revised.gapMs);
    if (spec?.sameItem(revised) != true) return;
    spec = revised;
    if (wasCompleted) _completed = true;
    await _persist();
    _publish();
  }

  /// An explicit playback request. Browsing uses catalog metadata, never this
  /// method. Pause/Stop/supersession invalidate the intent even during loading.
  Future<void> loadAndStart(SessionSpec request) {
    _previewing = false;
    _transitioning = false;
    _transitionOwner = null;
    _startClock = Stopwatch()..start();
    startupStages.clear();
    _startupStage('requested');
    return _loadAndStart(request);
  }

  Future<void> _loadAndStart(
    SessionSpec request, {
    void Function(int)? owned,
    bool autoPlay = true,
    bool preserveSleep = false,
    int initialIndex = 0,
    Duration initialPosition = Duration.zero,
  }) async {
    final preparingOwner = _preparingOwner = Object();
    _preparingSpec = request;
    _stopped = false;
    try {
      if (!preserveSleep) {
        _sleepTimer?.cancel();
        _sleepDeadline = null;
      }
      final cachedDuration = durations[request.assetId];
      final load = cachedDuration == null
          ? inspect(_assetResolver(request.assetId))
          : Future.value(cachedDuration);
      if (cachedDuration != null) {
        ++_generation;
      }
      _wantedPlaying = autoPlay;
      _publish();
      final token = _generation;
      owned?.call(token);
      final duration = await load;
      if (token != _generation) return;
      final starting = _start(
        SessionSpec(
          assetId: request.assetId,
          durationMs: duration,
          startMs: request.startMs,
          endMs: request.isPassage ? request.endMs : duration,
          playCount: request.playCount,
          isPassage: request.isPassage,
          gapMs: request.gapMs,
          speed: request.speed,
          passageId: request.passageId,
          passageTitle: request.passageTitle,
        ),
        autoPlay: autoPlay,
        preserveSleep: preserveSleep,
        reuseSource: cachedDuration == null,
        initialIndex: initialIndex,
        initialPosition: initialPosition,
      );
      if (_generation == token + 1) owned?.call(_generation);
      await starting;
    } catch (error) {
      if (identical(_preparingOwner, preparingOwner) && !_stopped) {
        spec = request;
        _wantedPlaying = false;
        _completed = false;
        _failedPosition = Duration.zero;
        _failedPass = 1;
        lastError =
            'Could not load audio. Check its download or connection, then tap Play. $error';
        _event(lastError!);
      }
      rethrow;
    } finally {
      if (identical(_preparingOwner, preparingOwner)) {
        _preparingOwner = null;
        _preparingSpec = null;
        _publish();
      }
    }
  }

  /// Native playlist silence, including background playback; zero-gap keeps the
  /// original queue exactly. There is never a silence item after a finite end.
  Future<Uri> _silence(int milliseconds, {double speed = 1}) async {
    final directory = Directory('${store.root.path}/generated');
    await directory.create(recursive: true);
    final scaledMs = (milliseconds * speed).round();
    final file = File(
      '${directory.path}/gap-$milliseconds${speed == 1 ? '' : '-rate-${(speed * 1000).round()}'}.wav',
    );
    const rate = 8000;
    final samples = rate * scaledMs ~/ 1000, length = samples * 2;
    final data = ByteData(44 + length);
    void text(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        data.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    text(0, 'RIFF');
    data.setUint32(4, 36 + length, Endian.little);
    text(8, 'WAVE');
    text(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, rate, Endian.little);
    data.setUint32(28, rate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    text(36, 'data');
    data.setUint32(40, length, Endian.little);
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    return file.uri;
  }

  /// Timer belongs to the background handler. At expiry, trim the native queue
  /// to the current recitation so its real endpoint finishes the session.
  Future<void> setSleepTimer(
    Duration? delay, {
    bool afterPass = false,
    bool finishCurrentPass = true,
  }) async {
    _sleepTimer?.cancel();
    if (_sleepEnding &&
        !_completed &&
        delay == null &&
        !afterPass &&
        spec != null) {
      final request = spec!,
          currentPass = pass - 1,
          elapsed = position,
          intent = playing;
      await _start(
        request,
        autoPlay: intent,
        initialIndex: currentPass,
        initialPosition: elapsed,
        initialInGap: inGap,
      );
    }
    _sleepEnding = false;
    _sleepFinishPass = finishCurrentPass;
    _sleepDeadline = delay == null ? null : DateTime.now().add(delay);
    sleepLabel = afterPass
        ? 'After this pass'
        : delay == null
        ? 'Off'
        : '${delay.inMinutes} minutes';
    if (afterPass) {
      await _finishCurrentPass();
    } else if (delay != null) {
      _sleepTimer = Timer(delay, () {
        unawaited(
          finishCurrentPass && !_loading && !_transitioning
              ? _finishCurrentPass()
              : pause(),
        );
        if (!finishCurrentPass) {
          sleepLabel = 'Off';
          _sleepDeadline = null;
        }
      });
    }
    _event('sleep timer $sleepLabel');
  }

  Future<void> _finishCurrentPass() {
    final token = _generation;
    return _queue(() async {
      if (token != _generation || spec == null || _completed) return;
      _sleepEnding = true;
      sleepLabel = 'Finishing this pass';
      if (inGap) {
        await _player.pause();
        _completed = true;
        _event('completed pass=$pass reason=sleep-gap');
        _publish();
        return;
      }
      await _player.setLoopMode(LoopMode.off);
      final index = _player.currentIndex ?? 0;
      if (index + 1 < _player.audioSources.length) {
        await _player.removeAudioSourceRange(
          index + 1,
          _player.audioSources.length,
        );
      }
      _publish();
    });
  }

  void _beginPlayback() {
    _wantedPlaying = true;
    _startupStage('play-issued');
    unawaited(
      _player.play().catchError((Object error) {
        _fail(error, 'play');
      }),
    );
  }

  Future<void> _persist() async {
    if (spec != null && !_previewing) {
      await store.checkpoint(
        spec!,
        pass - 1,
        position.inMilliseconds.clamp(0, spec!.lengthMs),
      );
    }
  }

  // Event diagnostics remain available while idle. Periodic snapshots serve
  // active transport/loading only and stop entirely at the existing row cap.
  // This timer has no authority over audio or listening/timing callbacks.
  void _syncDiagnosticSampling() {
    if (_disposed ||
        _diagnosticFile == null ||
        _diagnosticRows >= 4000 ||
        (!_wantedPlaying && !_loading) ||
        _completed ||
        _stopped ||
        lastError != null) {
      _diagnosticTimer?.cancel();
      _diagnosticTimer = null;
      return;
    }
    _diagnosticTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      recordDiagnostic('sample');
      _syncDiagnosticSampling();
    });
  }

  void _publish() {
    _syncDiagnosticSampling();
    _observeListening();
    if (_loading) return;
    if (_player.processingState == ProcessingState.completed &&
        _preparingSpec == null &&
        spec != null &&
        _nativeGeneration == _generation &&
        !_completed &&
        lastError == null) {
      _completed = true;
      final advance =
          _wantedPlaying &&
          !_stopped &&
          !_previewing &&
          !_sleepEnding &&
          _seekInterrupted == null &&
          _endSeekGeneration != _generation &&
          spec?.continuesToNext == true &&
          nextSession != null;
      final finished = spec;
      _wantedPlaying = false;
      _transitioning = advance;
      final transitionOwner = _transitionOwner = advance ? Object() : null;
      _event(
        'completed pass=$pass reason=${_sleepEnding ? 'sleep' : 'finite-end'}',
      );
      // Player event streams are synchronous. Mutating the player in this
      // callback would re-enter its controller; serialize after this event.
      final completedGeneration = _generation;
      unawaited(
        _queue(() async {
              if (completedGeneration != _generation || !_completed) return;
              await _player.pause();
              await _persist();
            })
            .then((_) async {
              if (advance && finished != null) {
                await _advance(finished, completedGeneration, transitionOwner!);
              }
            })
            .catchError((Object error) {
              lastError = 'Completion pause failed: $error';
              _event(lastError!);
            }),
      );
    }
    // Android derives its central Play/Pause action from transport intent.
    // Buffering freezes position extrapolation. Repeat silence stays ready at
    // zero media speed so Android keeps Pause instead of a Connecting spinner.
    // In-app progress/animation uses progressing independently of intent.
    final state = loading
        ? AudioProcessingState.buffering
        : AudioProcessingState.values[_player.processingState.index];
    playbackState.add(
      PlaybackState(
        controls: [
          const MediaControl(
            androidIcon: 'drawable/ic_replay_10',
            label: 'Back 10 seconds',
            action: MediaAction.rewind,
          ),
          playRequested || playing ? MediaControl.pause : MediaControl.play,
          const MediaControl(
            androidIcon: 'drawable/ic_forward_10',
            label: 'Forward 10 seconds',
            action: MediaAction.fastForward,
          ),
          MediaControl.stop,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: state,
        playing: playRequested && !_stopped && lastError == null,
        updatePosition: Duration(
          milliseconds: position.inMilliseconds.clamp(0, spec?.lengthMs ?? 0),
        ),
        bufferedPosition: Duration(
          milliseconds: _player.bufferedPosition.inMilliseconds.clamp(
            0,
            spec?.lengthMs ?? 0,
          ),
        ),
        speed: inGap ? 0 : _player.speed,
        queueIndex: _player.playbackEvent.currentIndex,
      ),
    );
    final current = displaySession;
    if (current != null) {
      final item = MediaItem(
        id: current.assetId,
        extras: {
          'isPassage': current.isPassage,
          if (current.passageId != null) 'passageId': current.passageId,
        },
        title: current.isPassage
            ? (current.passageTitle?.trim().isNotEmpty == true
                  ? current.passageTitle!
                  : 'Passage')
            : _assetResolver(current.assetId).name,
        artist: current.isPassage
            ? '${_assetResolver(current.assetId).name} · ${_assetResolver(current.assetId).reciter}'
            : [
                _assetResolver(current.assetId).reciter,
                ?_assetResolver(current.assetId).riwayah,
              ].join(' · '),
        album: _assetResolver(current.assetId).name,
        duration: Duration(milliseconds: current.lengthMs),
      );
      final previous = mediaItem.value;
      // MediaItem equality compares only id in audio_service 0.18.19. Compare
      // displayed fields explicitly so renames publish without per-event spam.
      if (previous == null ||
          previous.id != item.id ||
          previous.title != item.title ||
          previous.artist != item.artist ||
          previous.album != item.album ||
          previous.duration != item.duration ||
          previous.extras?['passageId'] != item.extras?['passageId'] ||
          previous.extras?['isPassage'] != item.extras?['isPassage']) {
        mediaItem.add(item);
      }
    }
    revision.value++;
  }

  Future<void> _advance(SessionSpec finished, int token, Object owner) async {
    bool owns() => identical(_transitionOwner, owner);
    bool current() =>
        owns() && token == _generation && _transitioning && !_stopped;
    SessionSpec? attempted;
    try {
      if (!current()) return;
      final next = await nextSession!(finished);
      if (!current()) return;
      if (next == null || (_sleepDeadline?.isBefore(DateTime.now()) ?? false)) {
        _transitioning = false;
        _publish();
        return;
      }
      _event('auto-next from=${finished.assetId} to=${next.assetId}');
      attempted = next;
      _startClock = Stopwatch()..start();
      startupStages.clear();
      _startupStage('auto-next-requested');
      await _loadAndStart(next, preserveSleep: true);
    } catch (error) {
      if (owns() && !_stopped && _transitioning) {
        _wantedPlaying = false;
        if (attempted != null) spec = attempted;
        lastError =
            'Could not start the next surah. Check its download or connection, then tap Play. $error';
        _event(lastError!);
      }
    } finally {
      // Newer explicit requests own their state and must not be overwritten.
      if (owns()) {
        _transitioning = false;
        _transitionOwner = null;
        _publish();
      }
    }
  }

  @override
  Future<void> rewind() => seek(position - const Duration(seconds: 10));
  @override
  Future<void> fastForward() => seek(position + const Duration(seconds: 10));

  @override
  Future<void> play() async {
    _listeningDiscontinuity();
    if (spec == null) return;
    if (_restoredMetadata) {
      final restored = spec!;
      final restoredPass = pass;
      final restoredPosition = position;
      await _loadAndStart(
        restored,
        initialIndex: restoredPass - 1,
        initialPosition: restoredPosition,
      );
      return;
    }
    if (lastError != null) {
      throw StateError(
        'Load the recording again before resuming after an error.',
      );
    }
    if (completed) {
      await start(spec!);
      return;
    }
    final token = ++_generation;
    _wantedPlaying = true;
    _stopped = false;
    _recovering = false;
    await _queue(() async {
      if (token == _generation) {
        _nativeGeneration = token;
        _beginPlayback();
      }
    });
  }

  @override
  Future<void> pause() {
    _listeningDiscontinuity();
    ++_generation;
    _wantedPlaying = false;
    _preparingSpec = null;
    _preparingOwner = null;
    _transitioning = false;
    _transitionOwner = null;
    _recovering = false;
    _localBufferTimer?.cancel();
    _localBufferTimer = null;
    if (!_loading) _nativeGeneration = _generation;
    _resumeAfterInterruption = false;
    return _queue(() async {
      await _player.pause();
      await _persist();
      _event('paused pass=$pass');
    }, pauseOnError: false);
  }

  @override
  Future<void> stop() {
    _listeningDiscontinuity();
    _wantedPlaying = false;
    _preparingSpec = null;
    _preparingOwner = null;
    _stopped = true;
    _transitioning = false;
    _transitionOwner = null;
    _recovering = false;
    _localBufferTimer?.cancel();
    _localBufferTimer = null;
    _sleepTimer?.cancel();
    _sleepDeadline = null;
    sleepLabel = 'Off';
    ++_generation;
    _resumeAfterInterruption = false;
    return _queue(() async {
      await _player.stop();
      await _persist();
      _event('stopped');
    });
  }

  @override
  Future<void> seek(Duration position) {
    _listeningDiscontinuity();
    final request = spec;
    if (request == null) return Future.value();
    if (_restoredMetadata) {
      _failedPosition = Duration(
        milliseconds: position.inMilliseconds.clamp(0, request.lengthMs),
      );
      _publish();
      return _persist();
    }
    final token = ++_generation;
    _recovering = false;
    _localBufferTimer?.cancel();
    _localBufferTimer = null;
    return _queue(() async {
      if (token != _generation ||
          spec?.sameItem(request) != true ||
          spec?.startMs != request.startMs ||
          spec?.endMs != request.endMs) {
        return;
      }
      _nativeGeneration = token;
      final target = position.inMilliseconds.clamp(0, request.lengthMs);
      // Native completion can arrive after the seek Future resolves. A seek
      // to the end is not natural completion, even with a delayed callback.
      _endSeekGeneration = target == request.lengthMs ? token : null;
      final gap = _failedInGap ?? inGap;
      final recitationIndex = gap && _player.currentIndex != null
          ? _player.currentIndex! - 1
          : null;
      if (recitationIndex != null) {
        // A transport seek addresses the recitation, never the silence URI.
        // Returning from its gap is still the same transport pass.
        _continuousPass = pass;
        _previousIndex = recitationIndex;
      }
      final interrupted = Completer<void>();
      _seekInterrupted = interrupted;
      recordDiagnostic(
        'seek committed relativeMs=$target sourceMs=${request.relativeToSource(target)} pass=$pass',
      );
      try {
        await Future.any([
          _player.seek(Duration(milliseconds: target), index: recitationIndex),
          interrupted.future,
        ]);
      } finally {
        if (identical(_seekInterrupted, interrupted)) _seekInterrupted = null;
      }
      if (interrupted.isCompleted || token != _generation) return;
      _failedPosition = null;
      _failedPass = null;
      _failedInGap = null;
      _failedGapPosition = null;
      if (_wantedPlaying && !_player.playing && !_stopped && !_completed) {
        _beginPlayback();
      }
      await _persist();
      _event(
        'seek relativeMs=$target sourceMs=${request.relativeToSource(target)} pass=$pass',
      );
      if (!usingLocal &&
          !_stopped &&
          _player.processingState == ProcessingState.idle) {
        // This newer seek may have cancelled verification of an errored remote
        // source. Recover using this target and intent, never the older one.
        unawaited(_recoverToLocal(token));
      }
    }, generation: token);
  }

  void _interruptPendingSeek() {
    final pending = _seekInterrupted;
    if (pending != null && !pending.isCompleted) pending.complete();
  }

  @override
  Future<void> setSpeed(double speed) async {
    _listeningDiscontinuity();
    final current = spec;
    if (current == null) return;
    final request = current.withOptions(speed: speed);
    if (_restoredMetadata) {
      spec = request;
      await _persist();
      _publish();
      return;
    }
    if (speed == current.speed) return;
    final token = _generation;
    await _queue(() async {
      if (token != _generation || spec != current) return;
      if (current.gapMs > 0 && !_completed) {
        final silence = await _silence(current.gapMs, speed: speed);
        if (token != _generation) return;
        final wasGap = inGap;
        final intent = _wantedPlaying;
        final index = _player.currentIndex ?? 0;
        final gapPosition = Duration(
          milliseconds:
              (_player.position.inMilliseconds * speed / current.speed).round(),
        );
        _loading = true;
        try {
          if (wasGap) await _player.pause();
          // Replace only generated silence. The recitation source and its
          // position stay attached to the native player throughout.
          for (var i = _player.audioSources.length - 1; i >= 1; i--) {
            if (i.isEven) continue;
            await _player.insertAudioSource(i + 1, AudioSource.uri(silence));
            await _player.removeAudioSourceAt(i);
          }
          if (spec?.sameItem(current) != true) return;
          await _player.setSpeed(speed);
          if (wasGap) await _player.seek(gapPosition, index: index);
          if (spec?.sameItem(current) != true) return;
          _previousIndex = _player.currentIndex ?? index;
          spec = request;
          if (wasGap && intent && token == _generation && !_stopped) {
            _beginPlayback();
          }
        } finally {
          _loading = false;
        }
      } else {
        await _player.setSpeed(speed);
        if (token != _generation) return;
        spec = request;
      }
      await _persist();
      _publish();
    }, generation: token);
  }

  Future<void> updateOptions({
    required double speed,
    required int gapMs,
  }) async {
    final current = spec;
    if (current == null) return;
    if (gapMs == current.gapMs) return setSpeed(speed);
    if (_restoredMetadata) {
      spec = current.withOptions(speed: speed, gapMs: gapMs);
      await _persist();
      _publish();
      return;
    }
    await _start(
      current.withOptions(speed: speed, gapMs: gapMs),
      autoPlay: playing,
      initialPosition: inGap ? Duration.zero : position,
      preserveSleep: true,
    );
  }

  PlaybackPreview beginPreview() => PlaybackPreview._(this);
  Future<void> dispose() async {
    _observeListening();
    _listeningTimer?.cancel();
    _disposed = true;
    ++_generation;
    _localBufferTimer?.cancel();
    _sleepTimer?.cancel();
    _diagnosticTimer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
    await store.flush();
    await _diagnosticWrites;
    await listeningRecorder?.close();
    events.dispose();
    revision.dispose();
  }
}

/// Temporary playback owns no saved record/checkpoint. A later transport/source
/// command wins over rollback, so Cancel cannot resurrect cancelled playback.
class PlaybackPreview {
  PlaybackPreview._(this.handler)
    : original = handler.spec,
      index = handler.pass - 1,
      position = handler._player.position,
      wasPlaying = handler.playing,
      wasGap = handler.inGap,
      wasCompleted = handler.completed,
      deadline = handler._sleepDeadline,
      finishPass = handler._sleepFinishPass,
      ending = handler._sleepEnding;
  final PrototypeHandler handler;
  final SessionSpec? original;
  final int index;
  final Duration position;
  final bool wasPlaying, wasGap, wasCompleted, finishPass, ending;
  final DateTime? deadline;
  int? ownedGeneration;
  bool closed = false;
  bool? _returnPlaying;
  bool get ownsPlayback =>
      !closed &&
      ownedGeneration != null &&
      ownedGeneration == handler._generation;
  Future<void> preview(SessionSpec request, {bool autoPlay = true}) async {
    if (closed) return;
    handler._previewing = true;
    await handler._loadAndStart(
      request,
      owned: (token) => ownedGeneration = token,
      autoPlay: autoPlay,
    );
  }

  // Only controls explicitly belonging to this preview retain its rollback.
  // External notification/transport actions still invalidate ownership.
  Future<void> seek(Duration position) async {
    if (!ownsPlayback) return;
    final operation = handler.seek(position);
    ownedGeneration = handler._generation;
    await operation;
  }

  Future<void> setPlaying(bool value) async {
    if (!ownsPlayback) return;
    _returnPlaying = value;
    final operation = value ? handler.play() : handler.pause();
    ownedGeneration = handler._generation;
    await operation;
  }

  void commit() {
    closed = true;
    handler._previewing = false;
  }

  Future<void> restore() async {
    if (closed) return;
    closed = true;
    if (ownedGeneration == null || ownedGeneration != handler._generation) {
      handler._previewing = false;
      return;
    }
    try {
      if (original == null) {
        await handler.stop();
        handler.spec = null;
        handler._completed = false;
        handler.mediaItem.add(null);
        handler._publish();
      } else {
        final inspectGeneration = handler._generation + 1;
        await handler.inspect(handler._assetResolver(original!.assetId));
        if (handler._generation != inspectGeneration) return;
        final restoreGeneration = handler._generation + 1;
        await handler._start(
          original!,
          autoPlay: _returnPlaying ?? wasPlaying,
          initialIndex: index,
          initialPosition: position,
          initialInGap: wasGap,
        );
        if (handler._generation != restoreGeneration) return;
        handler._completed = wasCompleted;
        handler._publish();
        if (ending || deadline != null) {
          await handler.setSleepTimer(
            deadline == null
                ? null
                : Duration(
                    milliseconds: deadline!
                        .difference(DateTime.now())
                        .inMilliseconds
                        .clamp(0, 86400000),
                  ),
            afterPass: ending,
            finishCurrentPass: finishPass,
          );
        }
      }
    } finally {
      handler._previewing = false;
    }
    await handler._persist();
  }
}
