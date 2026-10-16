import 'dart:async';
import 'dart:io';

import 'package:al_murajaah/core/audio/prototype_handler.dart';
import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/features/support/support_content.dart';
import 'package:al_murajaah/features/support/story_repository.dart';
import 'package:al_murajaah/core/database/app_database.dart';
import 'package:al_murajaah/core/database/foundation_repository.dart';
import 'package:al_murajaah/features/catalog/catalog.dart';
import 'package:al_murajaah/features/catalog/catalog_repository.dart';
import 'package:al_murajaah/features/activity/listening_recorder.dart';
import 'package:al_murajaah/features/backup/metadata_backup.dart';
import 'package:al_murajaah/features/downloads/audio_files.dart';
import 'package:al_murajaah/features/downloads/download_queue.dart';
import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'stage4_offline_recovery_test.dart' show until;
import 'stage5_v19_playback_test.dart' show V19Player;
import 'listening_meter_test.dart' show sample;
import 'download_queue_test.dart' show FakeTransfers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('origin namespaces initialize and resolve through production files without transfers; unsafe paths reject', () async {
    final root = await Directory.systemTemp.createTemp('origin-files');
    final db = AppDatabase(NativeDatabase.memory());
    await FoundationRepository(db).readTheme();
    final catalog = Catalog.parse(
      await rootBundle.loadString('assets/catalog/zarami.json'),
    );
    await CatalogRepository(db).install(catalog);
    await StoryRepository(db).install();
    final files = AudioFiles(
      root,
      legacy: Directory('${root.path}/diagnostic_v1'),
    );
    final backend = FakeTransfers();
    final queue = DownloadQueue(db, files, backend, {
      for (final r in catalog.recordings) r.assetId: r.audioAsset,
      for (final r in storyRecordings) r.asset.id: r.asset,
    });
    try {
      await queue.initialize();
      for (final recording in storyRecordings) {
        expect(await queue.verifiedFile(recording.asset), isNull);
        final handler = PrototypeHandler(
          PrototypeStore(root),
          player: V19Player(),
          assetResolver: (_) => recording.asset,
          localResolver: queue.verifiedFile,
        );
        try {
          await handler.loadAndStart(recording.session);
          expect(handler.playing, true);
          expect(handler.usingLocal, false);
          expect(handler.mediaItem.value!.artist, recording.asset.reciter);
        } finally {
          await handler.dispose();
        }
      }
      expect(backend.starts, isEmpty);
      expect(await db.select(db.downloads).get(), isEmpty);
      for (final id in [
        '../brother-001',
        'brother-001/..',
        'origin-004.mp3',
        'origin-004\n',
        'brother-001\\other',
      ]) {
        final unsafe = SampleAsset(
          id,
          'Unsafe',
          'https://example.invalid/a',
          1,
          '0' * 64,
        );
        expect(() => files.durable(unsafe), throwsArgumentError);
      }
    } finally {
      queue.dispose();
      await db.close();
      await root.delete(recursive: true);
    }
  });
  test('origin registration preserves catalog and credits/backups through existing schema', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await FoundationRepository(db).readTheme();
    final catalog = Catalog.parse(
      await rootBundle.loadString('assets/catalog/zarami.json'),
    );
    final repository = CatalogRepository(db);
    await repository.install(catalog);
    final original = await db.select(db.audioAssets).get();
    final recorder = ListeningRecorder(db);
    try {
      await StoryRepository(db).install();
      await StoryRepository(db).install();
      final installed = await db.select(db.audioAssets).get();
      expect(installed.length, original.length + 4);
      for (final asset in original) {
        expect(installed.where((a) => a.id == asset.id).single, asset);
      }
      expect((await repository.load())!.recordings, hasLength(114));
      expect((await db.select(db.downloads).get()), isEmpty);
      recorder.observe(sample(0, 0), storyRecordings.first.asset.id, null);
      recorder.observe(
        sample(1000, 1000),
        storyRecordings.first.asset.id,
        null,
      );
      await recorder.flush();
      expect(recorder.error.value, isNull);
      expect(
        (await db.select(db.listeningSessions).getSingle()).assetId,
        'brother-001',
      );
      final backup = MetadataBackup(db);
      final text = await backup.export();
      final preview = await backup.preview(text);
      expect(preview.duplicateEvents, 1);
      expect(preview.newEvents, 0);
      await FoundationRepository(db).verifyIntegrity();
    } finally {
      await recorder.close();
      await db.close();
    }
  });
  for (final recording in [storyRecordings.first, storyRecordings.last]) {
    test(
      '${recording.asset.id} publishes its credit and ends without catalog advance',
      () async {
        final root = await Directory.systemTemp.createTemp('origin-playback');
        final player = V19Player();
        var advances = 0;
        final handler = PrototypeHandler(
          PrototypeStore(root),
          player: player,
          assetResolver: (id) =>
              storyRecordings.singleWhere((r) => r.asset.id == id).asset,
          localResolver: (_) async => null,
          nextSession: (_) {
            advances++;
            return null;
          },
        );
        try {
          await handler.loadAndStart(recording.session);
          expect(handler.mediaItem.value!.title, recording.asset.name);
          expect(handler.mediaItem.value!.artist, recording.asset.reciter);
          expect(handler.mediaItem.value!.id, recording.asset.id);
          expect(handler.mediaItem.value!.artist, isNot(contains('Zarami')));
          player.finish(twice: true);
          await until(() => handler.completed && !player.playing);
          expect(advances, 0);
          expect(player.plays, 1);
          expect(handler.spec!.assetId, recording.asset.id);
        } finally {
          await handler.dispose();
          await root.delete(recursive: true);
        }
      },
    );
  }
  test(
    'Pause cancels a loading story request without delayed autoplay',
    () async {
      final root = await Directory.systemTemp.createTemp('origin-cancel');
      final player = V19Player()..loading = Completer<void>();
      final recording = storyRecordings.first;
      final handler = PrototypeHandler(
        PrototypeStore(root),
        player: player,
        assetResolver: (_) => recording.asset,
        localResolver: (_) async => null,
      );
      try {
        final loading = handler.loadAndStart(recording.session);
        await until(() => handler.loading);
        final pause = handler.pause();
        player.loading!.complete();
        await Future.wait([loading, pause]);
        expect(player.plays, 0);
        expect(handler.playRequested, false);
      } finally {
        await handler.dispose();
        await root.delete(recursive: true);
      }
    },
  );
}
