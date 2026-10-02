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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      from1To2: (m, schema) =>
          m.addColumn(schema.appSettings, schema.appSettings.updatedUtcMs),
    ),
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA busy_timeout = 5000');
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement(
        'INSERT OR IGNORE INTO app_settings (id) VALUES (1)',
      );
    },
  );
}
