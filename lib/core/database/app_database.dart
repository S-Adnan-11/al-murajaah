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
  int get schemaVersion => 4;

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
    },
  );
}
