import 'package:al_murajaah/core/database/app_database.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'database/generated/foundation/generated/schema.dart';
import 'fixtures/foundation_fixture.dart';

// Keep the accepted release's historical v6 migration proof at its target.
class AcceptedReleaseDatabase extends AppDatabase {
  AcceptedReleaseDatabase(super.executor);
  @override
  int get schemaVersion => 6;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final version in [1, 2, 3, 4, 5]) {
    test(
      'populated v$version to v6 preserves prior rows and backfills credited listening best',
      () async {
        final helper = GeneratedHelper();
        final verifier = SchemaVerifier(helper);
        final schema = await verifier.schemaAt(version);
        final old = helper.databaseForVersion(schema.newConnection(), version);
        await old.customStatement(
          "INSERT INTO app_settings (id,theme,network_policy) VALUES (1,'dark','any')",
        );
        await seedFoundationFixture(old);
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
        final before = <String, List<Map<String, Object?>>>{};
        for (final table in tables) {
          before[table] = (await old.customSelect('SELECT * FROM $table').get())
              .map((r) => Map<String, Object?>.of(r.data))
              .toList();
        }
        final db = AcceptedReleaseDatabase(schema.newConnection());
        try {
          await verifier.migrateAndValidate(db, 6);
          for (final table in tables) {
            final after = (await db.customSelect('SELECT * FROM $table').get())
                .map((r) => Map<String, Object?>.of(r.data))
                .toList();
            if (table == 'app_settings') {
              if (version < 2) expect(after.single.remove('updated_utc_ms'), 0);
              if (version < 3) expect(after.single.remove('aurora_enabled'), 0);
            }
            expect(after, before[table], reason: 'preserve $table');
          }
          expect(
            (await db.select(db.listeningStreakRecords).getSingle()).bestDays,
            1,
          );
          expect(
            (await db.customSelect('PRAGMA integrity_check').getSingle())
                .data
                .values
                .single,
            'ok',
          );
          expect(
            await db.customSelect('PRAGMA foreign_key_check').get(),
            isEmpty,
          );
        } finally {
          await db.close();
          await old.close();
        }
      },
    );
  }
}
