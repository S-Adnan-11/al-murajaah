import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';

void main() {
  late Directory root;
  late PrototypeStore store;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('murajaah_store_test');
    store = PrototypeStore(root);
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });
  test(
    'verification rejects wrong size and equal-length corrupt bytes',
    () async {
      final asset = SampleAsset(
        'fixture',
        'fixture',
        '',
        3,
        sha256.convert([1, 2, 3]).toString(),
      );
      await store.audioFile(asset).writeAsBytes([1, 2]);
      expect(await store.isVerified(asset), false);
      await store.audioFile(asset).writeAsBytes([1, 2, 4]);
      expect(await store.isVerified(asset), false);
      await store.audioFile(asset).writeAsBytes([1, 2, 3]);
      expect(await store.isVerified(asset), true);
    },
  );
  test(
    'passages survive reopening/audio deletion; checkpoints serialize',
    () async {
      final spec = SessionSpec(
        assetId: samples.first.id,
        durationMs: 10000,
        startMs: 2000,
        endMs: 5000,
        playCount: 3,
        isPassage: true,
      );
      await store.savePassage('Revision', spec);
      await store.audioFile(samples.first).writeAsBytes([1]);
      await store.audioFile(samples.first).delete();
      await Future.wait([
        store.checkpoint(spec, 0, 0),
        store.checkpoint(spec, 1, 1200),
      ]);
      final reopened = PrototypeStore(root);
      expect((await reopened.passages()).single.spec.toJson(), spec.toJson());
      expect((await reopened.readCheckpoint())!['positionMs'], 1200);
    },
  );
  test('sample identities/digests are distinct and well formed', () {
    expect(samples.map((a) => a.id).toSet().length, 3);
    for (final asset in samples) {
      expect(asset.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(Uri.parse(asset.url).host, 'res.cloudinary.com');
    }
  });
}
