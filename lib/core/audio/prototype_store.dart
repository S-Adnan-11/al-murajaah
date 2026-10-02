import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import 'sample_catalog.dart';
import 'session_spec.dart';

class SavedPassage {
  SavedPassage(this.title, this.spec);
  final String title;
  final SessionSpec spec;
}

/// Stage 1 foreground download experiment, not the production download queue.
class PrototypeStore {
  PrototypeStore(this.root);
  final Directory root;
  bool _downloading = false;
  Future<void> _writes = Future.value();
  static Future<PrototypeStore> open() async {
    final base = await getApplicationSupportDirectory();
    final root = Directory('${base.path}/diagnostic_v1');
    await root.create(recursive: true);
    return PrototypeStore(root);
  }

  File audioFile(SampleAsset asset) => File('${root.path}/${asset.id}.mp3');
  Future<bool> isVerified(SampleAsset asset) async {
    final path = audioFile(asset).path;
    final bytes = asset.bytes;
    final expectedHash = asset.sha256;
    // Async reads alone don't move the crypto transform off the UI isolate.
    return Isolate.run(() => _verifyFile(path, bytes, expectedHash));
  }

  Future<File?> verifiedFile(SampleAsset asset) async =>
      await isVerified(asset) ? audioFile(asset) : null;

  Future<File> download(
    SampleAsset asset,
    void Function(int, int) progress, {
    void Function(String)? onStage,
  }) async {
    if (_downloading) {
      throw StateError('Another diagnostic download is active.');
    }
    _downloading = true;
    final path = audioFile(asset).path;
    final url = asset.url;
    final bytes = asset.bytes;
    final expectedHash = asset.sha256;
    final updates = ReceivePort();
    final subscription = updates.listen((dynamic message) {
      final update = message as List<dynamic>;
      onStage?.call(update[0] as String);
      progress(update[1] as int, bytes);
    });
    final sendPort = updates.sendPort;
    try {
      final result = await _runDownloadWorker(
        path,
        url,
        bytes,
        expectedHash,
        sendPort,
      );
      return File(result);
    } finally {
      await subscription.cancel();
      updates.close();
      _downloading = false;
    }
  }

  Future<void> _write(String name, Object data) {
    final next = _writes.then((_) async {
      final temporary = File('${root.path}/$name.part');
      await temporary.writeAsString(jsonEncode(data), flush: true);
      await temporary.rename('${root.path}/$name');
    });
    _writes = next.catchError((Object _) {});
    return next;
  }

  Future<Object?> _read(String name) async {
    await _writes;
    final file = File('${root.path}/$name');
    if (!await file.exists()) return null;
    return jsonDecode(await file.readAsString());
  }

  Future<List<SavedPassage>> passages() async {
    final records = await _read('passages.json') as List<dynamic>? ?? [];
    return records.map((record) {
      final spec = SessionSpec.fromJson(
        Map<String, dynamic>.from(record['spec']),
      );
      assetById(spec.assetId); // Reject unknown identities.
      return SavedPassage(record['title'] as String, spec);
    }).toList();
  }

  Future<void> savePassage(String title, SessionSpec spec) async {
    if (title.trim().isEmpty || !spec.isPassage) {
      throw ArgumentError('Name a passage.');
    }
    final records = await passages();
    records.add(SavedPassage(title.trim(), spec));
    await _write(
      'passages.json',
      records.map((p) => {'title': p.title, 'spec': p.spec.toJson()}).toList(),
    );
  }

  Future<void> checkpoint(SessionSpec spec, int index, int relativeMs) =>
      _write('checkpoint.json', {
        'spec': spec.toJson(),
        'index': index,
        'positionMs': relativeMs,
      });
  Future<Map<String, dynamic>?> readCheckpoint() async =>
      await _read('checkpoint.json') as Map<String, dynamic>?;
}

Future<bool> _verifyFile(String path, int bytes, String expectedHash) async {
  final file = File(path);
  if (!await file.exists() || await file.length() != bytes) return false;
  return (await sha256.bind(file.openRead()).first).toString() == expectedHash;
}

// Keep the spawned closure in its own scope. A closure made inside download()
// can also capture the UI progress callback/ReceivePort context, which may
// contain unsendable objects and must never enter the worker isolate.
Future<String> _runDownloadWorker(
  String path,
  String url,
  int bytes,
  String expectedHash,
  SendPort updates,
) => Isolate.run(() => _downloadFile(path, url, bytes, expectedHash, updates));

Future<String> _downloadFile(
  String path,
  String url,
  int bytes,
  String expectedHash,
  SendPort updates,
) async {
  final part = File('$path.part');
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  IOSink? sink;
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close().timeout(const Duration(seconds: 30));
    if (response.statusCode != 200 ||
        response.headers.contentType?.mimeType != 'audio/mpeg' ||
        (response.contentLength != -1 && response.contentLength != bytes)) {
      throw const FormatException('Unexpected audio response or byte size.');
    }
    var received = 0;
    final progressClock = Stopwatch()..start();
    updates.send(['downloading', 0]);
    sink = part.openWrite();
    // addStream honors sink backpressure instead of accumulating writes per chunk.
    await sink.addStream(
      response.timeout(const Duration(seconds: 30)).map((chunk) {
        received += chunk.length;
        if (received > bytes) {
          throw const FormatException('Audio is too large.');
        }
        if (progressClock.elapsedMilliseconds >= 200) {
          updates.send(['downloading', received]);
          progressClock.reset();
        }
        return chunk;
      }),
    );
    await sink.flush();
    await sink.close();
    sink = null;
    updates.send(['verifying', received]);
    if (received != bytes ||
        !await _verifyFile(part.path, bytes, expectedHash)) {
      throw const FormatException('Audio size or SHA-256 mismatch.');
    }
    return (await part.rename(path)).path;
  } finally {
    client.close(force: true);
    await sink?.close();
    if (await part.exists()) await part.delete();
  }
}
