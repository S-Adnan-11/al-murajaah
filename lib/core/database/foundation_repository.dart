import 'dart:convert';

import 'package:drift/drift.dart';

import 'app_database.dart';

/// Repositories are the write boundary. SQLite transactions serialize clients;
/// the shared worker and unique event IDs make duplicate callbacks harmless.
class FoundationRepository {
  FoundationRepository(this.db);
  final AppDatabase db;

  Future<String> readTheme() async =>
      (await db.select(db.appSettings).getSingle()).theme;

  Future<void> saveTheme(String theme) async {
    if (!{'system', 'light', 'dark'}.contains(theme)) {
      throw ArgumentError.value(theme, 'theme');
    }
    await db.transaction(() async {
      await db.customStatement(
        'UPDATE app_settings SET theme = ?, updated_utc_ms = ? WHERE id = 1',
        [theme, DateTime.now().toUtc().millisecondsSinceEpoch],
      );
    });
  }

  Future<void> savePassage(SavedPassagesCompanion passage) async {
    if (!passage.id.present ||
        !RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(passage.id.value)) {
      throw ArgumentError('A saved passage requires a UUID');
    }
    // SQL constraints/triggers validate count, duration and immutable asset FK.
    await db.into(db.savedPassages).insertOnConflictUpdate(passage);
  }

  Future<List<SavedPassage>> passages() => (db.select(
    db.savedPassages,
  )..orderBy([(t) => OrderingTerm.asc(t.createdUtcMs)])).get();

  Future<void> deletePassage(String id) async {
    await (db.delete(db.savedPassages)..where((t) => t.id.equals(id))).go();
  }

  Future<void> setFavorite(String type, String target, bool favorite) async {
    if (favorite) {
      await db
          .into(db.favorites)
          .insert(
            FavoritesCompanion.insert(
              type: type,
              targetId: target,
              createdUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    } else {
      await (db.delete(
        db.favorites,
      )..where((t) => t.type.equals(type) & t.targetId.equals(target))).go();
    }
  }

  Future<void> saveDownload(DownloadsCompanion download) async {
    await db.into(db.downloads).insertOnConflictUpdate(download);
  }

  Future<void> saveCheckpoint(PlaybackCheckpointsCompanion checkpoint) async {
    await db.into(db.playbackCheckpoints).insertOnConflictUpdate(checkpoint);
  }

  /// Credit only an already-measured progressing interval. The caller must
  /// split midnight/timezone boundaries; this foundation creates no UI timers.
  Future<bool> creditMeasuredInterval({
    required String eventId,
    required String sessionId,
    required String localDate,
    required String timezonePolicy,
    required int wallMs,
    required int goalMs,
    required int utcMs,
  }) => db.transaction(() async {
    if (wallMs <= 0 ||
        goalMs < 0 ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(localDate) ||
        timezonePolicy.trim().isEmpty) {
      throw ArgumentError('Invalid measured interval/date policy');
    }
    final previous = await (db.select(
      db.activityEvents,
    )..where((t) => t.id.equals(eventId))).getSingleOrNull();
    if (previous != null) {
      if (previous.sessionId != sessionId ||
          previous.localDate != localDate ||
          previous.playedWallMs != wallMs ||
          previous.utcMs != utcMs) {
        throw StateError('Conflicting replay of activity event $eventId');
      }
      return false;
    }
    await db.customStatement(
      'INSERT OR IGNORE INTO daily_activity '
      '(local_date,timezone_policy,played_wall_ms,goal_ms,qualified) VALUES (?,?,0,?,0)',
      [localDate, timezonePolicy, goalMs],
    );
    await db
        .into(db.activityEvents)
        .insert(
          ActivityEventsCompanion.insert(
            id: eventId,
            sessionId: sessionId,
            localDate: localDate,
            playedWallMs: wallMs,
            utcMs: utcMs,
          ),
        );
    await db.customStatement(
      'UPDATE daily_activity SET played_wall_ms = played_wall_ms + ?, '
      'qualified = CASE WHEN goal_ms > 0 AND played_wall_ms + ? >= goal_ms THEN 1 ELSE 0 END '
      'WHERE local_date = ?',
      [wallMs, wallMs, localDate],
    );
    await db.customStatement(
      'UPDATE listening_sessions SET played_wall_ms = played_wall_ms + ? WHERE id = ?',
      [wallMs, sessionId],
    );
    return true;
  });

  /// A background callback shares the same server/transaction authority.
  /// Do not pass database objects directly to Isolate.run or reopen the file.
  Future<T> inWorker<T>(Future<T> Function(FoundationRepository) action) =>
      db.computeWithDatabase(
        connect: AppDatabase.new,
        computation: (connection) => action(FoundationRepository(connection)),
      );

  Future<void> verifyIntegrity() async {
    final integrity = await db.customSelect('PRAGMA integrity_check').get();
    final foreignKeys = await db.customSelect('PRAGMA foreign_key_check').get();
    if (integrity.length != 1 ||
        integrity.single.data.values.single != 'ok' ||
        foreignKeys.isNotEmpty) {
      throw StateError('Foundation database integrity check failed');
    }
  }

  static String settingsSnapshot(Map<String, Object?> settings) =>
      jsonEncode(settings);
}
