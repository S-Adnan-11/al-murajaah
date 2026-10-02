import 'package:al_murajaah/core/database/app_database.dart';
import 'package:al_murajaah/core/database/foundation_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/foundation_fixture.dart';
import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;

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
  late SchemaVerifier verifier;
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('schema v1 -> v2 matches full exported schema', () async {
    final schema = await verifier.schemaAt(1);
    final db = AppDatabase(schema.newConnection());
    try {
      await verifier.migrateAndValidate(db, 2);
    } finally {
      await db.close();
    }
  });

  test(
    'populated v1 -> v2 preserves every entity and explicit theme',
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
      final db = AppDatabase(schema.newConnection());
      try {
        await verifier.migrateAndValidate(db, 2);
        for (final table in tables) {
          final after = (await db.customSelect('SELECT * FROM $table').get())
              .map((row) => Map<String, Object?>.from(row.data))
              .toList();
          if (table == 'app_settings') {
            expect(after.single.remove('updated_utc_ms'), 0);
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
}
