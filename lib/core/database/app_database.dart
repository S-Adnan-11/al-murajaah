import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'app_database.steps.dart';

part 'app_database.g.dart';

/// One logical database and SQLite worker per app process. Callbacks must share
/// this connection (computeWithDatabase), never open a competing writer.
@DriftDatabase(include: {'foundation.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  factory AppDatabase.file(File file) =>
      AppDatabase(NativeDatabase.createInBackground(file));

  @override
  int get schemaVersion => 7;

  /// Calendar-day groups, independent of goals. Max retains legitimate older
  /// records if daily detail is later pruned; imports never add streak lengths.
  Future<void> reconcileBestListeningStreak({int importedBest = 0}) async {
    await customStatement(
      'INSERT OR IGNORE INTO listening_streak_records (id) VALUES (1)',
    );
    await customStatement(
      '''
      UPDATE listening_streak_records SET best_days = MAX(best_days, ?, COALESCE((
        SELECT MAX(days) FROM (
          SELECT COUNT(*) AS days FROM (
            SELECT julianday(local_date) - ROW_NUMBER() OVER (ORDER BY local_date) AS run
            FROM daily_activity WHERE played_wall_ms > 0
          ) GROUP BY run
        )
      ), 0)) WHERE id = 1
    ''',
      [importedBest],
    );
    markTablesUpdated([listeningStreakRecords]);
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Table rebuilds must not activate ON DELETE SET NULL or remove stars.
      // Disable FKs outside the transaction; validate every reference before
      // commit and always re-enable enforcement, including failed upgrades.
      await customStatement('PRAGMA foreign_keys = OFF');
      try {
        await transaction(() async {
          await stepByStep(
            from1To2: (m, schema) => m.addColumn(
              schema.appSettings,
              schema.appSettings.updatedUtcMs,
            ),
            from2To3: (m, schema) => m.addColumn(
              schema.appSettings,
              schema.appSettings.auroraEnabled,
            ),
            from3To4: (m, schema) async {
              await m.alterTable(TableMigration(schema.savedPassages));
              await m.alterTable(TableMigration(schema.listeningSessions));
            },
            from4To5: (m, schema) async {
              await customStatement(
                'DROP TRIGGER IF EXISTS favorite_insert_target',
              );
              await customStatement(
                'DROP TRIGGER IF EXISTS favorite_update_target',
              );
              await m.alterTable(TableMigration(schema.favorites));
              await m.create(schema.favoriteInsertTarget);
              await m.create(schema.favoriteUpdateTarget);
              await m.create(schema.recordingDeleteFavorite);
            },
            from5To6: (m, schema) =>
                m.createTable(schema.listeningStreakRecords),
            from6To7: (m, schema) async {
              await m.addColumn(
                schema.appSettings,
                schema.appSettings.alternateHomeText,
              );
              await m.addColumn(
                schema.appSettings,
                schema.appSettings.homeTextLanguage,
              );
              // Rebuild only to change the SQL default. Every stored choice,
              // including Wi-Fi-only from an earlier default, is retained.
              await m.alterTable(TableMigration(schema.appSettings));
            },
          )(m, from, to);
          if ((await customSelect(
            'PRAGMA foreign_key_check',
          ).get()).isNotEmpty) {
            throw StateError('Database migration reference validation failed');
          }
        });
      } finally {
        await customStatement('PRAGMA foreign_keys = ON');
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA busy_timeout = 5000');
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement(
        // Only genuinely absent preferences get the new download default.
        // Existing and imported settings, including Wi-Fi-only, are untouched.
        'INSERT OR IGNORE INTO app_settings (id,network_policy) VALUES (1,\'any\')',
      );
      if (schemaVersion >= 6) await reconcileBestListeningStreak();
    },
  );
}
