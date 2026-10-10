import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../core/audio/sample_catalog.dart';

/// Durable app-private files. Existing verified diagnostic files are reused
/// where they are; no implicit migration or duplicate retained audio copy.
class AudioFiles {
  AudioFiles(this.base, {this.legacy});
  final Directory base;
  final Directory? legacy;
  // Process-local trust only: a new process hashes again. A cache entry is
  // bound to immutable revision/digest AND all observable file metadata.
  final _verified = <String, FileStat>{};
  final _pending = <String, Future<File?>>{};
  int verificationReads = 0;
  int verificationCacheHits = 0;

  bool _sameFile(FileStat a, FileStat b) =>
      a.type == FileSystemEntityType.file &&
      b.type == FileSystemEntityType.file &&
      a.size == b.size &&
      a.modified == b.modified &&
      a.changed == b.changed &&
      a.mode == b.mode;
  void _validate(SampleAsset asset) {
    if (!RegExp(r'^zarami-hafs-\d{3}-v[1-9]\d*$').hasMatch(asset.id)) {
      throw ArgumentError('Unsafe recording identity');
    }
  }

  File durable(SampleAsset asset) {
    _validate(asset);
    return File(p.join(base.path, 'audio', '${asset.id}.mp3'));
  }

  Future<bool> hasRetainedCandidate(SampleAsset asset) async =>
      await durable(asset).exists() ||
      (legacy != null &&
          await File(p.join(legacy!.path, '${asset.id}.mp3')).exists());

  Future<File?> verifiedFile(SampleAsset asset) {
    _validate(asset);
    final key = '${asset.id}:${asset.bytes}:${asset.sha256}';
    return _pending.putIfAbsent(key, () async {
      try {
        return await _verify(asset);
      } finally {
        _pending.remove(key);
      }
    });
  }

  Future<File?> _verify(SampleAsset asset) async {
    _validate(asset);
    final paths = [
      durable(asset).path,
      if (legacy != null) p.join(legacy!.path, '${asset.id}.mp3'),
    ];
    final bytes = asset.bytes, hash = asset.sha256;
    for (final path in paths) {
      final file = File(path);
      final key = '${asset.id}:$bytes:$hash:$path';
      final before = await file.stat();
      if (before.type != FileSystemEntityType.file || before.size != bytes) {
        _verified.remove(key);
        continue;
      }
      final cached = _verified[key];
      if (cached != null && _sameFile(cached, before)) {
        verificationCacheHits++;
        return file;
      }
      _verified.remove(key);
      verificationReads++;
      final valid = await Isolate.run(
        () async =>
            (await sha256.bind(File(path).openRead()).first).toString() == hash,
      );
      final after = await file.stat();
      if (valid && _sameFile(before, after)) {
        _verified[key] = after;
        return file;
      }
    }
    return null;
  }

  String relative(File file) {
    final path = p.relative(file.path, from: base.path).replaceAll('\\', '/');
    if (p.isAbsolute(path) || path.contains('..') || path.contains(':')) {
      throw StateError('Retained audio must remain inside app storage');
    }
    return path;
  }

  Future<File> prepare(SampleAsset asset, String sourcePath, int token) async {
    final finalFile = durable(asset);
    await finalFile.parent.create(recursive: true);
    final destination = '${finalFile.path}.$token.part';
    final bytes = asset.bytes, hash = asset.sha256;
    // Native staging can live on another filesystem: copy to an internal part,
    // hash in the worker and only then allow atomic promotion in that directory.
    return File(
      await Isolate.run(() async {
        final part = File(destination);
        try {
          final source = File(sourcePath);
          if (await source.length() != bytes) {
            throw const FormatException('Download size mismatch');
          }
          final sink = part.openWrite();
          try {
            await sink.addStream(source.openRead());
            await sink.flush();
          } finally {
            await sink.close();
          }
          if (await part.length() != bytes ||
              (await sha256.bind(part.openRead()).first).toString() != hash) {
            throw const FormatException('Download checksum mismatch');
          }
          return part.path;
        } catch (_) {
          if (await part.exists()) await part.delete();
          rethrow;
        }
      }),
    );
  }

  Future<int> delete(SampleAsset asset) async {
    _validate(asset);
    _verified.removeWhere((key, _) => key.startsWith('${asset.id}:'));
    var reclaimed = 0;
    for (final file in [
      durable(asset),
      if (legacy != null) File(p.join(legacy!.path, '${asset.id}.mp3')),
    ]) {
      if (await file.exists()) {
        reclaimed += await file.length();
        await file.delete();
      }
    }
    return reclaimed;
  }
}
