import 'dart:io';

import 'package:al_murajaah/app/product_dependencies.dart';
import 'package:al_murajaah/core/audio/prototype_handler.dart';
import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:al_murajaah/core/database/app_database.dart';
import 'package:al_murajaah/features/catalog/catalog.dart';
import 'package:al_murajaah/features/catalog/catalog_repository.dart';
import 'package:al_murajaah/features/downloads/audio_files.dart';
import 'package:al_murajaah/features/downloads/download_queue.dart';
import 'package:al_murajaah/features/product/product_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'download_queue_test.dart' show FakeTransfers;
import 'playback_intent_test.dart' show HeldPlayer;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final paused in [false, true]) {
    test(
      'active Edit preserves UUID/stars; title keeps transport, boundaries preserve source/pass, Create is independent, paused=$paused',
      () async {
        final root = await Directory.systemTemp.createTemp('edit-saved');
        final dbFile = File('${root.path}/library.sqlite');
        var db = AppDatabase(NativeDatabase(dbFile));
        final catalog = Catalog.parse(
          await rootBundle.loadString('assets/catalog/zarami.json'),
        );
        await CatalogRepository(db).install(catalog);
        final assets = {
          for (final r in catalog.recordings) r.assetId: r.audioAsset,
        };
        final queue = DownloadQueue(
          db,
          AudioFiles(root),
          FakeTransfers(),
          assets,
          pollInterval: const Duration(days: 1),
        );
        final player = HeldPlayer();
        final h = PrototypeHandler(
          PrototypeStore(root),
          player: player,
          localResolver: (_) async => null,
        );
        final c = ProductController(
          h,
          ProductDependencies(catalog, assets, queue),
        );
        var closed = false;
        try {
          await c.select(catalog.recordings.first);
          final clip = SessionSpec(
            assetId: catalog.recordings.first.assetId,
            durationMs: 10000,
            startMs: 2000,
            endMs: 5000,
            isPassage: true,
            playCount: 3,
          );
          await c.saveDraft(clip, 'Original', create: true);
          final original = c.saved.single;
          expect(c.passageFavorites, isEmpty, reason: 'Saving never stars');
          await c.favoritePassage(original);
          expect(c.favorites, isEmpty, reason: 'Passage star is independent');
          await c.playViewed(restart: true);
          player.index(1);
          player.position = const Duration(milliseconds: 1000);
          await Future<void>.delayed(Duration.zero);
          if (paused) await h.pause();
          final loads = player.loads, pauses = player.pauses;
          await c.saveDraft(h.spec!, 'Renamed', note: 'same record');
          expect(c.saved.single.id, original.id);
          expect(c.saved.single.row.createdUtcMs, original.row.createdUtcMs);
          expect(h.spec!.passageTitle, 'Renamed');
          expect(h.pass, 2);
          expect(h.position.inMilliseconds, 1000);
          expect(h.playing, !paused);
          expect(player.loads, loads);
          expect(player.pauses, pauses);
          expect(c.passageFavorites, contains(original.id));
          await c.changeCount(1);
          expect(h.pass, 2);
          expect(h.position.inMilliseconds, 1000);
          expect(h.playing, !paused);
          expect(c.message, contains('This play will finish, then stop'));
          await c.saveDraft(
            h.spec!.withCount(null),
            'Renamed',
            note: 'same record',
          );
          expect(
            c.message,
            isNull,
            reason: 'Continuous clears the reached-limit wording',
          );
          expect(h.pass, 2);
          expect(player.loads, loads);
          await c.saveDraft(
            SessionSpec(
              assetId: clip.assetId,
              durationMs: 10000,
              startMs: 3000,
              endMs: 7000,
              isPassage: true,
              playCount: 5,
            ),
            'Revised',
          );
          expect(h.spec!.passageId, original.id);
          expect(h.spec!.startMs, 3000);
          expect(h.spec!.endMs, 7000);
          expect(h.pass, 2);
          expect(h.position, Duration.zero);
          expect(h.playing, !paused);
          final revised = c.saved.single;
          final active = h.spec, revisedLoads = player.loads;
          await c.saveDraft(clip, 'Another', create: true);
          expect(c.saved, hasLength(2));
          expect(c.savedId, isNot(original.id));
          expect(
            c.saved.singleWhere((p) => p.id == original.id).row,
            revised.row,
          );
          expect(h.spec, same(active));
          expect(player.loads, revisedLoads);
          expect(c.passageFavorites, {original.id});
          expect(c.saved.map((p) => p.row.assetId).toSet(), {clip.assetId});
          final rowsBeforeFailure = await c.library.read();
          await db.customStatement(
            "CREATE TEMP TRIGGER reject_edit BEFORE UPDATE ON saved_passages BEGIN SELECT RAISE(ABORT, 'test write failure'); END",
          );
          await expectLater(
            c.saveDraft(clip, 'Must not save'),
            throwsA(anything),
          );
          expect(
            (await c.library.read()).map((p) => p.row),
            rowsBeforeFailure.map((p) => p.row),
          );
          expect(h.spec, same(active));
          expect(player.loads, revisedLoads);
          await db.customStatement('DROP TRIGGER reject_edit');

          // Persistence and playback failure are separate results.
          c.viewSaved(revised);
          player.loadError = StateError('native clip failure');
          final revisedRange = SessionSpec(
            assetId: clip.assetId,
            durationMs: 10000,
            startMs: 4000,
            endMs: 8000,
            isPassage: true,
            playCount: 5,
          );
          await expectLater(
            c.saveDraft(revisedRange, 'Persisted before native failure'),
            throwsA(isA<SavedPlaybackUpdateException>()),
          );
          expect(
            (await c.library.read())
                .singleWhere((p) => p.id == original.id)
                .row
                .startMs,
            4000,
          );
          player.loadError = null;
          c.dispose();
          queue.dispose();
          closed = true;
          await db.close();
          db = AppDatabase(NativeDatabase(dbFile));
          expect(await db.select(db.savedPassages).get(), hasLength(2));
          expect(
            (await db.select(db.favorites).get()).single.targetId,
            original.id,
          );
          expect(
            (await db.select(db.savedPassages).get())
                .singleWhere((p) => p.id == original.id)
                .startMs,
            4000,
          );
        } finally {
          // Controller/queue were closed before file-backed reopen on success.
          if (!closed) {
            c.dispose();
            queue.dispose();
          }
          await h.dispose();
          await db.close();
          await root.delete(recursive: true);
        }
      },
    );
  }
  test('named speed save updates one row; saved Play starts A, Continue resumes; draft options never alter active audio', () async {
    final root = await Directory.systemTemp.createTemp('saved-options');
    final db = AppDatabase(NativeDatabase.memory());
    final catalog = Catalog.parse(
      await rootBundle.loadString('assets/catalog/zarami.json'),
    );
    await CatalogRepository(db).install(catalog);
    final assets = {
      for (final r in catalog.recordings) r.assetId: r.audioAsset,
    };
    final queue = DownloadQueue(
      db,
      AudioFiles(root),
      FakeTransfers(),
      assets,
      pollInterval: const Duration(days: 1),
    );
    final player = HeldPlayer();
    final h = PrototypeHandler(
      PrototypeStore(root),
      player: player,
      localResolver: (_) async => null,
    );
    final c = ProductController(h, ProductDependencies(catalog, assets, queue));
    try {
      await c.select(catalog.recordings.first);
      c.editPassage(
        SessionSpec(
          assetId: catalog.recordings.first.assetId,
          durationMs: 79256,
          startMs: 2000,
          endMs: 5000,
          isPassage: true,
          playCount: 3,
          speed: .75,
        ),
      );
      await c.save('Named');
      final id = c.savedId;
      await c.save('Renamed', note: 'keep note');
      expect(c.saved, hasLength(1));
      expect(c.saved.single.id, id);
      expect(c.saved.single.row.speed, .75);
      expect(h.spec, isNull, reason: 'Save does not start playback');
      c.viewSaved(c.saved.single);
      await c.playViewed();
      expect(h.spec!.passageId, id);
      expect(h.spec!.passageTitle, 'Renamed');
      expect(player.speed, .75);
      player.index(1);
      player.position = const Duration(seconds: 1);
      await Future<void>.delayed(Duration.zero);
      await h.pause();
      c.showActive();
      await c.playViewed();
      expect(h.pass, 2);
      expect(
        h.position,
        const Duration(seconds: 1),
        reason: 'Continue resumes',
      );
      c.viewSaved(c.saved.single);
      expect(
        c.viewedIsActive,
        true,
        reason: 'Opening the exact active save shows its live session',
      );
      expect(h.pass, 2);
      expect(h.position, const Duration(seconds: 1));
      await c.playViewed(restart: true);
      expect(h.pass, 1);
      expect(h.position, Duration.zero, reason: 'saved Play begins at A');
      final active = h.spec;
      await c.select(catalog.recordings[8]);
      await c.applyOptions(speed: .9, gapMs: 0);
      expect(h.spec, same(active));
      expect(player.speed, .75);
      expect(c.viewedSpec!.speed, .9);
      await c.select(catalog.recordings.first);
      await c.playFullViewed();
      expect(h.spec!.isPassage, false);
      expect(h.spec!.playCount, 1);
      expect(player.speed, 1);
    } finally {
      c.dispose();
      queue.dispose();
      await h.dispose();
      await db.close();
      await root.delete(recursive: true);
    }
  });
}
