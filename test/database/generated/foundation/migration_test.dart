import 'package:al_murajaah/core/database/app_database.dart';
import 'package:al_murajaah/core/database/foundation_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/foundation_fixture.dart';
import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v4.dart' as v4;

import 'package:al_murajaah/features/support/story_repository.dart';
import 'package:al_murajaah/features/catalog/catalog_repository.dart';
import 'package:al_murajaah/features/catalog/catalog.dart';
import 'package:flutter/services.dart';

// Preserve the historical v1/v2 -> V18 schema-3 proofs at their original target.
class V18Database extends AppDatabase {
  V18Database(super.executor);
  @override
  int get schemaVersion => 3;
}

class V20Database extends AppDatabase {
  V20Database(super.executor);
  @override
  int get schemaVersion => 4;
}

class V25Database extends AppDatabase {
  V25Database(super.executor);
  @override
  int get schemaVersion => 5;
}

const tables = [
  'reciters',
  'app_settings',
  'surahs',
  'recording_editions',
  'audio_assets',
  'saved_passages',
  'favorites',
  'downloads',
  'playback_checkpoints',
  'listening_sessions',
  'daily_activity',
  'activity_events',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SchemaVerifier verifier;
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    verifier = SchemaVerifier(GeneratedHelper());
  });

  for (final version in [1, 2, 3, 4]) {
    test(
      'populated v$version -> v5 retains all records and enables independent recording stars',
      () async {
        final schema = await verifier.schemaAt(version);
        final old = switch (version) {
          1 => v1.DatabaseAtV1(schema.newConnection()),
          2 => v2.DatabaseAtV2(schema.newConnection()),
          3 => v3.DatabaseAtV3(schema.newConnection()),
          _ => v4.DatabaseAtV4(schema.newConnection()),
        };
        await old.customStatement(
          "INSERT INTO app_settings (id,theme,network_policy) VALUES (1,'dark','any')",
        );
        await seedFoundationFixture(old);
        final before = <String, List<Map<String, Object?>>>{};
        for (final table in tables) {
          before[table] = (await old.customSelect('SELECT * FROM $table').get())
              .map((r) => Map<String, Object?>.of(r.data))
              .toList();
        }
        final db = V25Database(schema.newConnection());
        try {
          await verifier.migrateAndValidate(db, 5);
          for (final table in tables) {
            final after = (await db.customSelect('SELECT * FROM $table').get())
                .map((r) => Map<String, Object?>.of(r.data))
                .toList();
            if (table == 'app_settings') {
              if (version < 2) expect(after.single.remove('updated_utc_ms'), 0);
              if (version < 3) expect(after.single.remove('aurora_enabled'), 0);
            }
            expect(after, before[table], reason: 'preserved $table');
          }
          await CatalogRepository(db).install(
            Catalog.parse(
              await rootBundle.loadString('assets/catalog/zarami.json'),
            ),
          );
          await StoryRepository(db).install();
          final repo = FoundationRepository(db);
          await repo.setFavorite('recording', 'brother-001', true);
          expect(
            (await db.select(db.favorites).get())
                .where((r) => r.type == 'recording')
                .single
                .targetId,
            'brother-001',
          );
          await expectLater(
            repo.setFavorite('recording', 'missing-recording', true),
            throwsA(isA<Exception>()),
          );
          await expectLater(
            db.customStatement(
              "UPDATE favorites SET target_id='origin-004' WHERE type='recording'",
            ),
            throwsA(isA<Exception>()),
          );
          await db.customStatement(
            "DELETE FROM audio_assets WHERE id='brother-001'",
          );
          expect(
            (await db.select(db.favorites).get()).where(
              (r) => r.type == 'recording',
            ),
            isEmpty,
          );
          expect(
            (await db.select(db.favorites).get()).where(
              (r) => r.type == 'passage',
            ),
            hasLength(1),
          );
          await repo.verifyIntegrity();
        } finally {
          await db.close();
          await old.close();
        }
      },
    );
  }

  test('schema v1 -> v3 matches full exported schema', () async {
    final schema = await verifier.schemaAt(1);
    final db = V18Database(schema.newConnection());
    try {
      await verifier.migrateAndValidate(db, 3);
    } finally {
      await db.close();
    }
  });

  test(
    'populated v1 -> v3 preserves every entity and explicit theme',
    () async {
      final schema = await verifier.schemaAt(1);
      final old = v1.DatabaseAtV1(schema.newConnection());
      final before = <String, List<Map<String, Object?>>>{};
      await old.customStatement(
        "INSERT INTO app_settings (id,theme) VALUES (1,'dark')",
      );
      await seedFoundationFixture(old);
      for (final table in tables) {
        before[table] = (await old.customSelect('SELECT * FROM $table').get())
            .map((row) => Map<String, Object?>.from(row.data))
            .toList();
        expect(before[table], isNotEmpty, reason: 'populated $table');
      }
      final db = V18Database(schema.newConnection());
      try {
        await verifier.migrateAndValidate(db, 3);
        for (final table in tables) {
          final after = (await db.customSelect('SELECT * FROM $table').get())
              .map((row) => Map<String, Object?>.from(row.data))
              .toList();
          if (table == 'app_settings') {
            expect(after.single.remove('updated_utc_ms'), 0);
            expect(after.single.remove('aurora_enabled'), 0);
          }
          expect(after, before[table], reason: 'unchanged $table rows');
        }
        expect(await FoundationRepository(db).readTheme(), 'dark');
        await FoundationRepository(db).verifyIntegrity();
      } finally {
        await db.close();
        await old.close();
      }
    },
  );

  test('populated V16 schema v2 upgrades additively with aurora off', () async {
    final schema = await verifier.schemaAt(2);
    final old = v2.DatabaseAtV2(schema.newConnection());
    await old.customStatement(
      "INSERT INTO app_settings (id,theme,reduced_motion,daily_goal_ms,updated_utc_ms) VALUES (1,'dark',1,600000,99)",
    );
    await seedFoundationFixture(old);
    final before = <String, List<Map<String, Object?>>>{};
    for (final table in tables) {
      before[table] = (await old.customSelect('SELECT * FROM $table').get())
          .map((r) => Map<String, Object?>.of(r.data))
          .toList();
    }
    final db = V18Database(schema.newConnection());
    try {
      await verifier.migrateAndValidate(db, 3);
      for (final table in tables) {
        final after = (await db.customSelect('SELECT * FROM $table').get())
            .map((r) => Map<String, Object?>.of(r.data))
            .toList();
        if (table == 'app_settings') {
          expect(after.single.remove('aurora_enabled'), 0);
        }
        expect(after, before[table], reason: 'unchanged $table');
      }
      await FoundationRepository(db).verifyIntegrity();
    } finally {
      await db.close();
      await old.close();
    }
  });

  for (final version in [1, 2, 3]) {
    test(
      'populated v$version -> v4 preserves all data, triggers and references; accepts 2.20x',
      () async {
        final schema = await verifier.schemaAt(version);
        final old = switch (version) {
          1 => v1.DatabaseAtV1(schema.newConnection()),
          2 => v2.DatabaseAtV2(schema.newConnection()),
          _ => v3.DatabaseAtV3(schema.newConnection()),
        };
        await old.customStatement(
          "INSERT INTO app_settings (id,theme) VALUES (1,'dark')",
        );
        await seedFoundationFixture(old);
        final before = <String, List<Map<String, Object?>>>{};
        for (final table in tables) {
          before[table] = (await old.customSelect('SELECT * FROM $table').get())
              .map((r) => Map<String, Object?>.of(r.data))
              .toList();
        }
        final db = V20Database(schema.newConnection());
        try {
          await verifier.migrateAndValidate(db, 4);
          for (final table in tables) {
            final after = (await db.customSelect('SELECT * FROM $table').get())
                .map((r) => Map<String, Object?>.of(r.data))
                .toList();
            if (table == 'app_settings') {
              if (version < 2) expect(after.single.remove('updated_utc_ms'), 0);
              if (version < 3) expect(after.single.remove('aurora_enabled'), 0);
            }
            expect(after, before[table], reason: 'unchanged $table');
          }
          await db.customStatement(
            'UPDATE saved_passages SET speed=2.2 WHERE id=?',
            [fixturePassageId],
          );
          await db.customStatement(
            "UPDATE listening_sessions SET speed=2.2 WHERE id='fixture-session'",
          );
          expect((await db.select(db.savedPassages).getSingle()).speed, 2.2);
          expect(
            (await db.select(db.listeningSessions).getSingle()).speed,
            2.2,
          );
          await expectLater(
            db.customStatement('UPDATE saved_passages SET speed=2.21'),
            throwsA(isA<Exception>()),
          );
          await expectLater(
            db.customStatement('UPDATE saved_passages SET end_ms=11000'),
            throwsA(isA<Exception>()),
          );
          expect(
            (await db.select(db.playbackCheckpoints).getSingle()).passageId,
            fixturePassageId,
          );
          expect(
            (await db.select(db.listeningSessions).getSingle()).passageId,
            fixturePassageId,
          );
          expect(await db.select(db.favorites).get(), hasLength(1));
          await FoundationRepository(db).verifyIntegrity();
        } finally {
          await db.close();
          await old.close();
        }
      },
    );
  }
}
