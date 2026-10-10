import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/audio/sample_catalog.dart';
import '../../core/database/app_database.dart';
import 'audio_files.dart';
import 'transfer_backend.dart';

class DownloadEntry {
  const DownloadEntry(
    this.state,
    this.received, {
    this.taskId,
    this.path,
    this.message,
  });
  final String state;
  final int received;
  final String? taskId, path, message;
  bool get active => {'queued', 'running', 'verifying'}.contains(state);
  String get label => switch (state) {
    'verified' => 'Downloaded',
    'queued' => 'Queued',
    'verifying' => 'Verifying download',
    'running' => message ?? 'Downloading',
    'failed' => message ?? 'Download needs retry',
    'cancelled' => 'Download cancelled',
    _ => 'Not downloaded',
  };
}

/// Two native transfers at most. The observation timer never controls audio.
/// SQL checkpoints + native task IDs reconcile after process death. A partial
/// file is never published as a retained download; interruption permits retry.
class DownloadQueue extends ChangeNotifier {
  DownloadQueue(
    this.db,
    this.files,
    this.backend,
    this.assets, {
    this.pollInterval = const Duration(seconds: 1),
    this.retiredAssets = const {},
  });
  final AppDatabase db;
  final AudioFiles files;
  final TransferBackend backend;
  final Map<String, SampleAsset> assets;
  final Duration pollInterval;
  final Set<String> retiredAssets;
  final _entries = <String, DownloadEntry>{};
  final _active = <String>{};
  final _tokens = <String, int>{};
  final _verified = StreamController<String>.broadcast();
  Stream<String> get verifiedDownloads => _verified.stream;
  Timer? _timer;
  bool _pumping = false, _polling = false, _closed = false;
  Future<void> _writes = Future.value();
  Map<String, DownloadEntry> get entries => Map.unmodifiable(_entries);
  DownloadEntry entry(String id) =>
      _entries[id] ?? const DownloadEntry('none', 0);

  Future<void> initialize() async {
    for (final row in await db.select(db.downloads).get()) {
      if (!assets.containsKey(row.assetId)) continue;
      _tokens[row.assetId] = 1;
      final item = DownloadEntry(
        row.state == 'verifying' && row.nativeTaskId != null
            ? 'running'
            : row.state,
        row.receivedBytes,
        taskId: row.nativeTaskId,
        path: row.relativePath,
      );
      _entries[row.assetId] = item;
      if (retiredAssets.contains(row.assetId) && item.active) {
        if (item.taskId != null) await _cancelNative(item.taskId!);
        await _put(
          row.assetId,
          DownloadEntry(
            'failed',
            item.received,
            path: item.path,
            message:
                'Recording replaced; original retained files are preserved.',
          ),
        );
        continue;
      }
      if (item.active && row.nativeTaskId != null) _active.add(row.assetId);
      if (item.active && row.nativeTaskId == null && item.state != 'queued') {
        await _put(
          row.assetId,
          const DownloadEntry(
            'failed',
            0,
            message: 'Download interrupted. Retry.',
          ),
        );
      }
    }
    if (!_closed) notifyListeners();
    // An upgrade or a crash after file promotion can leave a valid retained
    // file without its SQL row. Discover only trusted catalog filenames, hash
    // actual candidates off the UI isolate and reuse them in place.
    for (final asset in assets.values) {
      if (_closed) break;
      if (entry(asset.id).active || entry(asset.id).state == 'verified') {
        continue;
      }
      if (!await files.hasRetainedCandidate(asset)) continue;
      final token = _tokens.update(asset.id, (v) => v + 1, ifAbsent: () => 1);
      final retained = await files.verifiedFile(asset);
      if (_closed || _tokens[asset.id] != token) continue;
      await _put(
        asset.id,
        retained == null
            ? const DownloadEntry(
                'failed',
                0,
                message: 'Retained download could not be verified. Retry.',
              )
            : DownloadEntry(
                'verified',
                asset.bytes,
                path: files.relative(retained),
              ),
        token: token,
      );
    }
    await poll();
    _kick();
  }

  Future<File?> verifiedFile(SampleAsset asset) async {
    final file = await files.verifiedFile(asset);
    if (file != null && entry(asset.id).state != 'verified') {
      final old = entry(asset.id);
      _tokens.update(asset.id, (v) => v + 1, ifAbsent: () => 1);
      if (old.taskId != null) await _cancelNative(old.taskId!);
      _active.remove(asset.id);
      await _put(
        asset.id,
        DownloadEntry('verified', asset.bytes, path: files.relative(file)),
      );
      _kick();
    }
    if (file == null && entry(asset.id).state == 'verified') {
      await _put(
        asset.id,
        const DownloadEntry(
          'failed',
          0,
          message: 'Download could not be verified. Retry.',
        ),
      );
    }
    return file;
  }

  Future<void> enqueue(SampleAsset asset) async {
    if (retiredAssets.contains(asset.id)) {
      throw StateError(
        'Recording replaced; use the current catalog recording.',
      );
    }
    if (_closed || entry(asset.id).active) return;
    if (!assets.containsKey(asset.id)) throw StateError('Unknown recording');
    final token = _tokens.update(asset.id, (v) => v + 1, ifAbsent: () => 1);
    // Reuse prior retained audio rather than fetching a second durable copy.
    final existing = await files.verifiedFile(asset);
    if (_tokens[asset.id] != token || _closed) return;
    if (existing != null) {
      await _put(
        asset.id,
        DownloadEntry('verified', asset.bytes, path: files.relative(existing)),
        token: token,
      );
      return;
    }
    await _put(asset.id, const DownloadEntry('queued', 0), token: token);
    _kick();
  }

  void _kick() {
    if (_closed) return;
    unawaited(
      _pump().catchError((Object error) {
        debugPrint('DOWNLOAD_QUEUE_ERROR $error');
      }),
    );
    if (_active.isNotEmpty) {
      _timer ??= Timer.periodic(pollInterval, (_) {
        unawaited(
          poll().catchError((Object error) {
            debugPrint('DOWNLOAD_POLL_ERROR $error');
          }),
        );
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> _pump() async {
    if (_pumping || _closed) return;
    _pumping = true;
    try {
      while (_active.length < 2 && !_closed) {
        final pending = _entries.keys.where(
          (id) => entry(id).state == 'queued' && !_active.contains(id),
        );
        if (pending.isEmpty) break;
        final id = pending.first, asset = assets[pending.first]!;
        final token = _tokens[id]!;
        _active.add(id);
        String? task;
        try {
          if (await backend.freeBytes().timeout(const Duration(seconds: 15)) <
              asset.bytes * 2 + 32 * 1024 * 1024) {
            throw StateError('Not enough free storage. Free space and retry.');
          }
          final settings = await db.select(db.appSettings).getSingle();
          task = await backend
              .start(asset, wifiOnly: settings.networkPolicy == 'wifi')
              .timeout(const Duration(seconds: 30));
          if (_tokens[id] != token || _closed) {
            await backend.cancel(task);
            _active.remove(id);
            continue;
          }
          await _put(
            id,
            DownloadEntry('running', 0, taskId: task),
            token: token,
          );
        } catch (error) {
          if (task != null) await _cancelNative(task);
          _active.remove(id);
          await _put(
            id,
            DownloadEntry(
              'failed',
              0,
              message: error is StateError
                  ? error.message.toString()
                  : 'Download could not start. Retry.',
            ),
            token: token,
          );
        }
      }
    } finally {
      _pumping = false;
    }
    if (_active.isNotEmpty && !_closed) {
      _timer ??= Timer.periodic(pollInterval, (_) {
        unawaited(
          poll().catchError((Object error) {
            debugPrint('DOWNLOAD_POLL_ERROR $error');
          }),
        );
      });
    }
  }

  Future<void> poll() async {
    if (_polling || _closed) return;
    _polling = true;
    try {
      for (final id in List<String>.of(_active)) {
        final item = entry(id), token = _tokens[id]!;
        if (item.taskId == null || item.state == 'verifying') continue;
        try {
          final native = await backend
              .status(item.taskId!)
              .timeout(const Duration(seconds: 15));
          if (_tokens[id] != token || _closed) continue;
          if (native.state == 'successful') {
            if (native.path == null) {
              throw StateError('Completed transfer has no file');
            }
            await _put(
              id,
              DownloadEntry('verifying', native.received, taskId: item.taskId),
              token: token,
            );
            unawaited(_verify(id, native.path!, item.taskId!, token));
          } else if (native.state == 'failed' || native.state == 'missing') {
            debugPrint('DOWNLOAD_NATIVE_FAILURE $id ${native.reason}');
            await _cancelNative(item.taskId!);
            _active.remove(id);
            await _put(
              id,
              const DownloadEntry(
                'failed',
                0,
                message: 'Download interrupted. Retry.',
              ),
              token: token,
            );
          } else {
            await _put(
              id,
              DownloadEntry(
                'running',
                native.received,
                taskId: item.taskId,
                message: native.state == 'paused'
                    ? 'Waiting for network'
                    : null,
              ),
              token: token,
            );
          }
        } catch (error) {
          debugPrint('DOWNLOAD_STATUS_ERROR $id $error');
          await _cancelNative(item.taskId!);
          _active.remove(id);
          await _put(
            id,
            const DownloadEntry(
              'failed',
              0,
              message: 'Download status unavailable. Retry.',
            ),
            token: token,
          );
        }
      }
    } finally {
      _polling = false;
      _kick();
    }
  }

  Future<void> _verify(String id, String source, String task, int token) async {
    File? part;
    try {
      final asset = assets[id]!;
      part = await files.prepare(asset, source, token);
      if (_tokens[id] != token || _closed) return;
      final file = await part.rename(files.durable(asset).path);
      part = null;
      await _put(
        id,
        DownloadEntry('verified', asset.bytes, path: files.relative(file)),
        token: token,
      );
      debugPrint(
        'DOWNLOAD_VERIFIED asset=$id bytes=${asset.bytes} sha256=${asset.sha256}',
      );
    } catch (error) {
      debugPrint('DOWNLOAD_VERIFY_FAILED $id $error');
      await _put(
        id,
        const DownloadEntry(
          'failed',
          0,
          message: 'Download could not be verified. Retry.',
        ),
        token: token,
      );
    } finally {
      if (part != null && await part.exists()) await part.delete();
      await _cancelNative(task);
      if (_tokens[id] == token) _active.remove(id);
      _kick();
    }
  }

  Future<void> _put(String id, DownloadEntry value, {int? token}) {
    final result = _writes.then((_) async {
      if (_closed || (token != null && token != _tokens[id])) return;
      await db.customStatement(
        'INSERT INTO downloads (asset_id,relative_path,native_task_id,state,received_bytes,verified_sha256,updated_utc_ms) '
        'VALUES (?,?,?,?,?,?,?) ON CONFLICT(asset_id) DO UPDATE SET '
        'relative_path=excluded.relative_path,native_task_id=excluded.native_task_id,state=excluded.state,'
        'received_bytes=excluded.received_bytes,verified_sha256=excluded.verified_sha256,updated_utc_ms=excluded.updated_utc_ms',
        [
          id,
          value.path,
          value.taskId,
          value.state,
          value.received,
          value.state == 'verified' ? assets[id]!.sha256 : null,
          DateTime.now().toUtc().millisecondsSinceEpoch,
        ],
      );
      if (!_closed && (token == null || token == _tokens[id])) {
        final newlyVerified =
            value.state == 'verified' && entry(id).state != 'verified';
        _entries[id] = value;
        notifyListeners();
        if (newlyVerified) _verified.add(id);
      }
    });
    _writes = result.catchError((Object _) {});
    return result;
  }

  Future<void> _cancelNative(String task) async {
    try {
      await backend.cancel(task).timeout(const Duration(seconds: 15));
    } catch (error) {
      debugPrint('DOWNLOAD_CANCEL_ERROR $task $error');
    }
  }

  Future<void> cancel(String id) async {
    final old = entry(id);
    _tokens.update(id, (v) => v + 1, ifAbsent: () => 1);
    _active.remove(id);
    if (old.taskId != null) await _cancelNative(old.taskId!);
    await _put(id, const DownloadEntry('cancelled', 0));
    _kick();
  }

  Future<int> delete(SampleAsset asset) async {
    await cancel(asset.id);
    final reclaimed = await files.delete(asset);
    await _put(asset.id, const DownloadEntry('cancelled', 0));
    return reclaimed;
  }

  @override
  void dispose() {
    _closed = true;
    _timer?.cancel();
    unawaited(_verified.close());
    super.dispose();
  }
}
