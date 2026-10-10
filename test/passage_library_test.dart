import 'dart:convert';
import 'dart:io';

import 'package:al_murajaah/core/audio/prototype_store.dart' as legacy;
import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:al_murajaah/core/database/app_database.dart';
import 'package:al_murajaah/core/database/foundation_repository.dart';
import 'package:al_murajaah/features/catalog/catalog.dart';
import 'package:al_murajaah/features/catalog/catalog_repository.dart';
import 'package:al_murajaah/features/product/passage_library.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('legacy saves import once without changing JSON; CRUD, favorites and gaps survive reopen and deletion does not resurrect', () async {
    final root = await Directory.systemTemp.createTemp('saved-crud');
    var db = AppDatabase.file(File('${root.path}/app.sqlite'));
    final store = legacy.PrototypeStore(root);
    final catalog = Catalog.parse(
      await rootBundle.loadString('assets/catalog/zarami.json'),
    );
    try {
      await CatalogRepository(db).install(catalog);
      final spec = SessionSpec(
        assetId: catalog.chapter(1).assetId,
        durationMs: 79263,
        startMs: 2000,
        endMs: 5000,
        isPassage: true,
        playCount: 10,
      );
      await store.savePassage('Older save', spec);
      final source = File('${root.path}/passages.json');
      final before = sha256.convert(await source.readAsBytes()).toString();
      var library = PassageLibrary(db);
      await library.importLegacy(store);
      await library.importLegacy(store);
      expect(await library.read(), hasLength(1));
      final imported = (await library.read()).single;
      await library.save(
        'Renamed',
        imported.spec,
        id: imported.id,
        note: 'Kept note',
      );
      final gap = SessionSpec(
        assetId: spec.assetId,
        durationMs: spec.durationMs,
        startMs: 2100,
        endMs: 5100,
        isPassage: true,
        playCount: null,
        gapMs: 5000,
      );
      await library.save('Duplicate', gap);
      await FoundationRepository(db).setFavorite('passage', imported.id, true);
      await db.close();
      db = AppDatabase.file(File('${root.path}/app.sqlite'));
      library = PassageLibrary(db);
      expect(
        (await library.read()).map((p) => p.title),
        containsAll(['Renamed', 'Duplicate']),
      );
      expect(
        (await library.read())
            .singleWhere((p) => p.title == 'Duplicate')
            .spec
            .gapMs,
        5000,
      );
      expect(await db.select(db.favorites).get(), hasLength(1));
      await library.delete(imported.id);
      await library.importLegacy(store);
      expect(await library.read(), hasLength(1));
      expect(await db.select(db.favorites).get(), isEmpty);
      expect(sha256.convert(await source.readAsBytes()).toString(), before);
      expect((await store.passages()).single.title, 'Older save');
      await FoundationRepository(db).verifyIntegrity();
    } finally {
      await db.close();
      await root.delete(recursive: true);
    }
  });
  test('097/098 replacement retires old identity and flags saved timestamps without remapping downloads, checkpoints or saves', () async {
    final root = await Directory.systemTemp.createTemp('recording-replaced');
    final db = AppDatabase.file(File('${root.path}/app.sqlite'));
    try {
      final newCatalog = Catalog.parse(
        await rootBundle.loadString('assets/catalog/zarami.json'),
      );
      final old = jsonDecode(
        await rootBundle.loadString('assets/catalog/zarami.json'),
      ) as Map<String, dynamic>;
      final rows = old['recordings'] as List;
      for (final n in [97, 98]) {
        final r = rows[n - 1], other = newCatalog.chapter(n == 97 ? 98 : 97);
        r['version'] = 1;
        r['assetId'] = 'zarami-hafs-${'$n'.padLeft(3, '0')}-v1';
        r['url'] =
            'https://res.cloudinary.com/yw5eprsc/video/upload/zarami-${'$n'.padLeft(3, '0')}.mp3';
        r['sha256'] = other.sha256;
        r['byteSize'] = other.byteSize;
        r['durationMs'] = other.durationMs;
      }
      final repo = CatalogRepository(db);
      await repo.install(Catalog.parse(jsonEncode(old)));
      final library = PassageLibrary(db);
      final s = SessionSpec(
        assetId: 'zarami-hafs-097-v1',
        durationMs: 176771,
        startMs: 100000,
        endMs: 120000,
        isPassage: true,
        playCount: 33,
      );
      await library.save('Retained original', s);
      final saved = (await library.read()).single;
      await db.customStatement(
        "INSERT INTO downloads (asset_id,relative_path,state,received_bytes,verified_sha256,updated_utc_ms) VALUES (?,?,'verified',?,?,0)",
        [
          s.assetId,
          'audio/${s.assetId}.mp3',
          2928618,
          newCatalog.chapter(98).sha256,
        ],
      );
      final beforeDownload = (await db.select(db.downloads).getSingle())
          .toJson();
      await db.customStatement(
        "INSERT INTO playback_checkpoints (session_id,scope,asset_id,passage_id,current_pass,remaining_count,source_position_ms,settings_snapshot,updated_utc_ms) VALUES ('retained','passage',?,?,7,26,110000,'{}',0)",
        [s.assetId, saved.id],
      );
      final beforeCheckpoint =
          (await db.select(db.playbackCheckpoints).getSingle()).toJson();
      final beforeSave = saved.row.toJson();
      await repo.install(newCatalog);
      await repo.install(newCatalog);
      expect((await library.read()).single.row.toJson(), beforeSave);
      expect((await library.read()).single.review, true);
      expect((await library.read()).single.spec.endMs, 120000);
      expect(
        (await db.select(db.downloads).getSingle()).toJson(),
        beforeDownload,
      );
      expect(
        (await db.select(db.playbackCheckpoints).getSingle()).toJson(),
        beforeCheckpoint,
      );
      expect((await repo.load())!.chapter(97).assetId, 'zarami-hafs-097-v2');
      expect(
        await repo.retiredAssets(),
        containsAll(['zarami-hafs-097-v1', 'zarami-hafs-098-v1']),
      );
      expect(await db.select(db.audioAssets).get(), hasLength(116));
      await FoundationRepository(db).verifyIntegrity();
    } finally {
      await db.close();
      await root.delete(recursive: true);
    }
  });
}
