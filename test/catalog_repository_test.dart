import 'dart:convert';
import 'dart:io';

import 'package:al_murajaah/core/database/app_database.dart';
import 'package:al_murajaah/core/database/foundation_repository.dart';
import 'package:al_murajaah/features/catalog/catalog.dart';
import 'package:al_murajaah/features/catalog/catalog_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/foundation_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String source;
  setUpAll(() async {
    source = await rootBundle.loadString('assets/catalog/zarami.json');
  });
  test('atomic install and reopen retain preferences, old assets and relational user data', () async {
    final root = await Directory.systemTemp.createTemp('catalog-install');
    final file = File('${root.path}/app.sqlite');
    var db = AppDatabase.file(file);
    try {
      final foundation = FoundationRepository(db);
      await foundation.saveTheme('dark');
      await seedFoundationFixture(db);
      final saved = (await foundation.passages()).single.toJson();
      final checkpoint = (await db.select(db.playbackCheckpoints).getSingle())
          .toJson();
      final download = (await db.select(db.downloads).getSingle()).toJson();
      final repo = CatalogRepository(db);
      final catalog = Catalog.parse(source);
      await repo.install(catalog);
      await repo.install(catalog);
      expect(await db.select(db.audioAssets).get(), hasLength(115));
      expect((await repo.load())!.recordings, hasLength(114));
      expect((await foundation.passages()).single.toJson(), saved);
      expect(
        (await db.select(db.playbackCheckpoints).getSingle()).toJson(),
        checkpoint,
      );
      expect((await db.select(db.downloads).getSingle()).toJson(), download);
      expect(await db.select(db.favorites).get(), hasLength(1));
      await db.close();
      db = AppDatabase.file(file);
      expect(await FoundationRepository(db).readTheme(), 'dark');
      expect(
        (await CatalogRepository(db).load())!.chapter(41).sha256,
        'd4668a46907e97b2d980a60d3e07435190dcf17f0faac4739ca1ee248ce74fb7',
      );
      expect(
        (await FoundationRepository(db).passages()).single.toJson(),
        saved,
      );
      await FoundationRepository(db).verifyIntegrity();
    } finally {
      await db.close();
      await root.delete(recursive: true);
    }
  });
  test('changed immutable metadata or malformed manifest leaves last good catalog intact', () async {
    final db = AppDatabase(NativeDatabase.memory());
    try {
      final repo = CatalogRepository(db);
      await repo.install(Catalog.parse(source));
      await FoundationRepository(db).saveTheme('light');
      final json = jsonDecode(source) as Map<String, dynamic>;
      json['recordings'][40]['sha256'] = 'a' * 64;
      await expectLater(
        repo.install(Catalog.parse(jsonEncode(json))),
        throwsStateError,
      );
      expect(
        (await repo.load())!.chapter(41).sha256,
        Catalog.parse(source).chapter(41).sha256,
      );
      expect(() => Catalog.parse('broken manifest'), throwsFormatException);
      expect((await repo.load())!.recordings, hasLength(114));
      expect(await FoundationRepository(db).readTheme(), 'light');
      await FoundationRepository(db).verifyIntegrity();
    } finally {
      await db.close();
    }
  });
  test('mid-install SQL failure rolls back all manifest rows and preserves prior data', () async {
    final db = AppDatabase(NativeDatabase.memory());
    try {
      final foundation = FoundationRepository(db);
      await foundation.saveTheme('dark');
      await seedFoundationFixture(db);
      await db.customStatement(
        "CREATE TRIGGER test_install_failure BEFORE INSERT ON audio_assets WHEN NEW.surah_number=60 BEGIN SELECT RAISE(ABORT,'test-only failure'); END",
      );
      await expectLater(
        CatalogRepository(db).install(Catalog.parse(source)),
        throwsA(isA<Exception>()),
      );
      expect(await db.select(db.audioAssets).get(), hasLength(1));
      expect(
        (await db.select(db.surahs).getSingle()).transliteration,
        'Fixture',
      );
      expect(await foundation.passages(), hasLength(1));
      expect(await foundation.readTheme(), 'dark');
      expect(await CatalogRepository(db).load(), isNull);
      await foundation.verifyIntegrity();
    } finally {
      await db.close();
    }
  });
}
