import 'dart:io';

import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/core/database/app_database.dart';
import 'package:al_murajaah/core/database/foundation_repository.dart';
import 'package:al_murajaah/features/downloads/audio_files.dart';
import 'package:al_murajaah/features/downloads/download_queue.dart';
import 'package:al_murajaah/features/downloads/transfer_backend.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTransfers implements TransferBackend {
  final tasks = <String, TransferStatus>{};
  final starts = <String>[];
  final wifi = <bool>[];
  int space = 1024 * 1024 * 1024;
  @override
  Future<int> freeBytes() async => space;
  @override
  Future<String> start(SampleAsset asset, {required bool wifiOnly}) async {
    final task = '${starts.length + 1}';
    starts.add(asset.id);
    wifi.add(wifiOnly);
    tasks[task] = const TransferStatus('running', 0);
    return task;
  }

  @override
  Future<TransferStatus> status(String taskId) async =>
      tasks[taskId] ?? const TransferStatus('missing', 0);
  @override
  Future<void> cancel(String taskId) async {
    tasks.remove(taskId);
  }
}

Future<void> waitFor(bool Function() condition) async {
  final end = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) {
      throw StateError('Bounded queue observation timed out');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

Future<List<SampleAsset>> seed(AppDatabase db, List<int> payload) async {
  await FoundationRepository(db).readTheme();
  await db.customStatement(
    "INSERT INTO reciters VALUES ('test-reciter','Test',NULL,'Fixture','Fixture')",
  );
  await db.customStatement(
    "INSERT INTO recording_editions VALUES ('test-edition','test-reciter','Hafs','Fixture')",
  );
  final assets = <SampleAsset>[];
  for (var number = 1; number <= 3; number++) {
    final id = 'zarami-hafs-${number.toString().padLeft(3, '0')}-v97';
    final asset = SampleAsset(
      id,
      'Synthetic $number',
      'https://example.invalid/fixture-$number.mp3',
      payload.length,
      sha256.convert(payload).toString(),
    );
    assets.add(asset);
    await db.customStatement(
      "INSERT INTO surahs VALUES (?, 'اختبار','Fixture','[]')",
      [number],
    );
    await db.customStatement(
      "INSERT INTO audio_assets VALUES (?, 'test-edition',?,97,?,'audio/mpeg',10000,?,?,'published')",
      [id, number, asset.url, asset.bytes, asset.sha256],
    );
  }
  return assets;
}

void main() {
  test('startup recognizes verified legacy and promoted files without transfer or duplication; corrupt retained bytes stay unavailable', () async {
    final root = await Directory.systemTemp.createTemp(
      'queue-retained-upgrade',
    );
    final db = AppDatabase(NativeDatabase.memory());
    final payload = [9, 8, 7], assets = await seed(db, [9, 8, 7]);
    final legacy = Directory('${root.path}/diagnostic_v1');
    await legacy.create();
    final files = AudioFiles(root, legacy: legacy), backend = FakeTransfers();
    final oldFile = File('${legacy.path}/${assets.first.id}.mp3');
    await oldFile.writeAsBytes(payload);
    await files.durable(assets[1]).parent.create(recursive: true);
    await files.durable(assets[1]).writeAsBytes(payload);
    await File('${legacy.path}/${assets[2].id}.mp3').writeAsBytes([9, 8, 6]);
    final queue = DownloadQueue(db, files, backend, {
      for (final asset in assets) asset.id: asset,
    }, pollInterval: const Duration(days: 1));
    try {
      await queue.initialize();
      expect(queue.entry(assets.first.id).state, 'verified');
      expect(
        queue.entry(assets.first.id).path,
        'diagnostic_v1/${assets.first.id}.mp3',
      );
      expect(queue.entry(assets[1].id).state, 'verified');
      expect(queue.entry(assets[1].id).path, 'audio/${assets[1].id}.mp3');
      expect(queue.entry(assets[2].id).state, 'failed');
      expect(queue.entry(assets[2].id).path, isNull);
      expect(backend.starts, isEmpty);
      expect(await files.durable(assets.first).exists(), false);
      expect(await oldFile.readAsBytes(), payload);
      await FoundationRepository(db).verifyIntegrity();
    } finally {
      queue.dispose();
      await db.close();
      await root.delete(recursive: true);
    }
  });
  test('two native tasks maximum; successful bytes verified and one durable copy reused', () async {
    final root = await Directory.systemTemp.createTemp('queue-success');
    final db = AppDatabase(NativeDatabase.memory());
    final payload = List<int>.generate(65536, (i) => i % 251);
    final assets = await seed(db, payload),
        backend = FakeTransfers(),
        files = AudioFiles(root);
    final queue = DownloadQueue(db, files, backend, {
      for (final a in assets) a.id: a,
    }, pollInterval: const Duration(days: 1));
    final verified = <String>[];
    final subscription = queue.verifiedDownloads.listen(verified.add);
    try {
      // Explicit retained Wi-Fi choice; fresh defaults are covered separately.
      await db.customStatement(
        "UPDATE app_settings SET network_policy='wifi' WHERE id=1",
      );
      await queue.initialize();
      for (final a in assets) {
        await queue.enqueue(a);
      }
      await waitFor(() => backend.starts.length == 2);
      expect(queue.entry(assets[2].id).state, 'queued');
      expect(backend.wifi, [true, true]);
      final incoming = File('${root.path}/native-1.part');
      await incoming.writeAsBytes(payload);
      backend.tasks['1'] = TransferStatus(
        'successful',
        payload.length,
        path: incoming.path,
      );
      await queue.poll();
      await waitFor(() => queue.entry(assets.first.id).state == 'verified');
      await waitFor(() => verified.isNotEmpty);
      expect(verified, [assets.first.id]);
      await waitFor(() => backend.starts.length == 3);
      expect(await files.durable(assets.first).readAsBytes(), payload);
      final stored = (await db.select(db.downloads).get()).singleWhere(
        (r) => r.assetId == assets.first.id,
      );
      expect(stored.verifiedSha256, assets.first.sha256);
      expect(stored.relativePath, 'audio/${assets.first.id}.mp3');
      await queue.enqueue(assets.first);
      expect(verified, [assets.first.id]);
      expect(backend.starts.length, 3);
      expect(
        await root
            .list(recursive: true)
            .where((f) => f.path.endsWith('.mp3'))
            .length,
        1,
      );
      for (final a in assets.skip(1)) {
        await queue.cancel(a.id);
      }
      await FoundationRepository(db).verifyIntegrity();
    } finally {
      await subscription.cancel();
      queue.dispose();
      await db.close();
      await root.delete(recursive: true);
    }
  });
  test('corruption and full disk fail safely; old retained audio and saved references survive deletion/redownload', () async {
    final root = await Directory.systemTemp.createTemp('queue-safety');
    final db = AppDatabase(NativeDatabase.memory());
    final payload = [1, 2, 3, 4],
        assets = await seed(db, [1, 2, 3, 4]),
        backend = FakeTransfers(),
        files = AudioFiles(root);
    final queue = DownloadQueue(db, files, backend, {
      for (final a in assets) a.id: a,
    }, pollInterval: const Duration(days: 1));
    try {
      await db.customStatement(
        "INSERT INTO saved_passages VALUES ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',?,'Keep me',2000,5000,'finite',3,0,1.0,NULL,1,1)",
        [assets.first.id],
      );
      await queue.enqueue(assets.first);
      await waitFor(() => backend.starts.length == 1);
      final bad = File('${root.path}/bad.part');
      await bad.writeAsBytes([1, 2, 3, 5]);
      backend.tasks['1'] = TransferStatus('successful', 4, path: bad.path);
      await queue.poll();
      await waitFor(() => queue.entry(assets.first.id).state == 'failed');
      expect(await files.durable(assets.first).exists(), false);
      expect(
        await root
            .list(recursive: true)
            .where((f) => f.path.contains('.mp3.') && f.path.endsWith('.part'))
            .length,
        0,
      );
      backend.space = 1;
      await queue.enqueue(assets[1]);
      await waitFor(() => queue.entry(assets[1].id).state == 'failed');
      expect(backend.starts.length, 1);
      expect(queue.entry(assets[1].id).message, contains('free storage'));
      await files.durable(assets.first).parent.create(recursive: true);
      await files.durable(assets.first).writeAsBytes(payload);
      backend.space = 1024 * 1024 * 1024;
      await queue.enqueue(assets.first);
      expect(queue.entry(assets.first.id).state, 'verified');
      expect(await queue.delete(assets.first), 4);
      expect(
        (await FoundationRepository(db).passages()).single.title,
        'Keep me',
      );
      await queue.enqueue(assets.first);
      await waitFor(() => backend.starts.length == 2);
      final good = File('${root.path}/good.part');
      await good.writeAsBytes(payload);
      backend.tasks['2'] = TransferStatus('successful', 4, path: good.path);
      await queue.poll();
      await waitFor(() => queue.entry(assets.first.id).state == 'verified');
      expect(
        (await FoundationRepository(db).passages()).single.assetId,
        assets.first.id,
      );
      expect(
        (await queue.verifiedFile(assets.first))!.path,
        files.durable(assets.first).path,
      );
      await FoundationRepository(db).verifyIntegrity();
    } finally {
      queue.dispose();
      await db.close();
      await root.delete(recursive: true);
    }
  });
  test('restart reconciles native completion and missing tasks; verified legacy files are reused without a second copy', () async {
    final root = await Directory.systemTemp.createTemp('queue-restart');
    final db = AppDatabase(NativeDatabase.memory());
    final payload = [9, 8, 7],
        assets = await seed(db, [9, 8, 7]),
        backend = FakeTransfers();
    final legacy = Directory('${root.path}/diagnostic_v1');
    await legacy.create();
    final files = AudioFiles(root, legacy: legacy);
    var queue = DownloadQueue(db, files, backend, {
      for (final a in assets) a.id: a,
    }, pollInterval: const Duration(days: 1));
    try {
      await queue.enqueue(assets.first);
      await waitFor(() => backend.starts.length == 1);
      final incoming = File('${root.path}/restart.part');
      await incoming.writeAsBytes(payload);
      queue.dispose();
      // Simulate a kill during verification, with native completion retained.
      await db.customStatement(
        "UPDATE downloads SET state='verifying' WHERE asset_id=?",
        [assets.first.id],
      );
      backend.tasks['1'] = TransferStatus('successful', 3, path: incoming.path);
      queue = DownloadQueue(db, files, backend, {
        for (final a in assets) a.id: a,
      }, pollInterval: const Duration(days: 1));
      await queue.initialize();
      await waitFor(() => queue.entry(assets.first.id).state == 'verified');
      final old = File('${legacy.path}/${assets[1].id}.mp3');
      await old.writeAsBytes(payload);
      await queue.enqueue(assets[1]);
      expect(backend.starts.length, 1);
      expect(
        queue.entry(assets[1].id).path,
        'diagnostic_v1/${assets[1].id}.mp3',
      );
      expect(await files.durable(assets[1]).exists(), false);
      await db.customStatement(
        "INSERT INTO downloads VALUES (?,NULL,'gone','running',2,NULL,1)",
        [assets[2].id],
      );
      queue.dispose();
      queue = DownloadQueue(db, files, backend, {
        for (final a in assets) a.id: a,
      }, pollInterval: const Duration(days: 1));
      await queue.initialize();
      expect(queue.entry(assets[2].id).state, 'failed');
      expect(await queue.verifiedFile(assets[1]), isNotNull);
      await FoundationRepository(db).verifyIntegrity();
    } finally {
      queue.dispose();
      await db.close();
      await root.delete(recursive: true);
    }
  });
}
