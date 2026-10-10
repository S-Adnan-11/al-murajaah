import 'dart:io';

import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/features/downloads/audio_files.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'verified exact revision is cached only while its actual file is unchanged',
    () async {
      final root = await Directory.systemTemp.createTemp('v19-files');
      final bytes = List.generate(4096, (i) => i % 256);
      final asset = SampleAsset(
        'zarami-hafs-001-v91',
        'Fixture',
        'https://invalid.example/audio',
        bytes.length,
        sha256.convert(bytes).toString(),
      );
      final files = AudioFiles(root);
      try {
        final file = files.durable(asset);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes, flush: true);
        expect((await files.verifiedFile(asset))!.path, file.path);
        expect(files.verificationReads, 1);
        await Future.wait(List.generate(8, (_) => files.verifiedFile(asset)));
        expect(files.verificationReads, 1);
        expect(files.verificationCacheHits, greaterThan(0));
        final cold = AudioFiles(root);
        expect(await cold.verifiedFile(asset), isNotNull);
        expect(
          cold.verificationReads,
          1,
          reason: 'no persisted trust without hashing',
        );
        final timestamp = await file.lastModified();
        await file.writeAsBytes(List.filled(bytes.length, 9), flush: true);
        await file.setLastModified(timestamp.add(const Duration(seconds: 1)));
        expect(await files.verifiedFile(asset), isNull);
        expect(files.verificationReads, 2);
        await file.writeAsBytes(bytes.take(12).toList(), flush: true);
        expect(await files.verifiedFile(asset), isNull);
        await files.delete(asset);
        expect(await files.verifiedFile(asset), isNull);
        await file.writeAsBytes(bytes, flush: true);
        expect(await files.verifiedFile(asset), isNotNull);
        final stale = SampleAsset(
          asset.id,
          asset.name,
          asset.url,
          asset.bytes,
          '0' * 64,
        );
        expect(await files.verifiedFile(stale), isNull);
        final revision = SampleAsset(
          'zarami-hafs-001-v92',
          asset.name,
          asset.url,
          asset.bytes,
          asset.sha256,
        );
        expect(await files.verifiedFile(revision), isNull);
      } finally {
        await root.delete(recursive: true);
      }
    },
  );
}
