import 'dart:convert';
import 'dart:isolate';

import 'package:drift/drift.dart' show Variable;

import '../../core/database/app_database.dart';
import '../../core/database/foundation_repository.dart';

typedef BackupRow = Map<String, Object?>;

class BackupPreview {
  const BackupPreview(
    this.data,
    this.newPassages,
    this.samePassages,
    this.conflicts,
    this.newEvents,
    this.duplicateEvents,
    this.settingsBefore,
  );
  final Map<String, Object?> data;
  final int newPassages, samePassages, newEvents, duplicateEvents;
  final List<String> conflicts;
  final BackupRow settingsBefore;
}

class ImportResult {
  const ImportResult(this.passages, this.conflicts, this.events);
  final int passages, conflicts, events;
}

/// Versioned metadata only. Never accepts catalog URLs, audio bytes, file paths,
/// download state or playback checkpoints. Existing identities win conflicts.
class MetadataBackup {
  MetadataBackup(this.db);
  final AppDatabase db;
  static const maxBytes = 32 * 1024 * 1024;
  static const _tables = {
    'passages': 'saved_passages',
    'stars': 'favorites',
    'days': 'daily_activity',
    'sessions': 'listening_sessions',
    'events': 'activity_events',
  };
  static const _settingKeys = {
    'theme',
    'reduced_motion',
    'network_policy',
    'daily_goal_ms',
    'aurora_enabled',
  };

  Future<BackupRow> _settings() async {
    final row =
        (await db
                .customSelect('SELECT * FROM app_settings WHERE id=1')
                .getSingle())
            .data;
    return {for (final key in _settingKeys) key: row[key]};
  }

  Future<String> export() async {
    final data = await db.transaction(() async {
      final snapshot = <String, Object?>{
        'format': 'al-murajaah-metadata',
        'version': 1,
        'exported_utc_ms': DateTime.now().toUtc().millisecondsSinceEpoch,
        'settings': await _settings(),
      };
      for (final entry in _tables.entries) {
        snapshot[entry.key] =
            (await db.customSelect('SELECT * FROM ${entry.value}').get())
                .map((r) => Map<String, Object?>.of(r.data))
                .toList();
      }
      snapshot['recordings'] =
          (await db
                  .customSelect(
                    'SELECT DISTINCT a.id,a.sha256,a.duration_ms FROM audio_assets a '
                    'WHERE a.id IN (SELECT asset_id FROM saved_passages UNION SELECT asset_id FROM listening_sessions)',
                  )
                  .get())
              .map((r) => Map<String, Object?>.of(r.data))
              .toList();
      return snapshot;
    });
    return encodeBackup(data);
  }

  Future<BackupPreview> preview(String text) async {
    final data = await decodeBackup(text);
    return db.transaction(() => _previewData(data));
  }

  Future<BackupPreview> _previewData(Map<String, Object?> data) async {
    final assets = {
      for (final a in await db.select(db.audioAssets).get()) a.id: a,
    };
    for (final recording in rows(data, 'recordings')) {
      final local = assets[recording['id']];
      if (local == null ||
          local.sha256 != recording['sha256'] ||
          local.durationMs != recording['duration_ms']) {
        throw const FormatException(
          'A recording is unavailable or has a different identity. Import on a device with the matching catalog.',
        );
      }
    }
    var added = 0, same = 0, events = 0, duplicate = 0;
    final conflicts = <String>[];
    for (final passage in rows(data, 'passages')) {
      final asset = assets[passage['asset_id']];
      if (asset == null ||
          (passage['end_ms'] as int) > (asset.durationMs ?? 0)) {
        throw const FormatException(
          'Passage is outside its trusted recording.',
        );
      }
      final existing = await db
          .customSelect(
            'SELECT * FROM saved_passages WHERE id=?',
            variables: [variable(passage['id'])],
          )
          .getSingleOrNull();
      if (existing == null) {
        added++;
      } else if (_equal(existing.data, passage)) {
        same++;
      } else {
        conflicts.add(passage['title'] as String);
      }
    }
    for (final session in rows(data, 'sessions')) {
      final existing = await (db.select(
        db.listeningSessions,
      )..where((s) => s.id.equals(session['id'] as String))).getSingleOrNull();
      if (existing != null &&
          (existing.assetId != session['asset_id'] ||
              existing.startedUtcMs != session['started_utc_ms'])) {
        throw const FormatException('Conflicting activity session identity.');
      }
    }
    for (final event in rows(data, 'events')) {
      final existing = await db
          .customSelect(
            'SELECT * FROM activity_events WHERE id=?',
            variables: [variable(event['id'])],
          )
          .getSingleOrNull();
      if (existing == null) {
        events++;
      } else if (_equal(existing.data, event)) {
        duplicate++;
      } else {
        throw const FormatException(
          'Conflicting listening event. Nothing was imported.',
        );
      }
    }
    for (final star in rows(data, 'stars')) {
      if (star['type'] == 'surah' &&
          await (db.select(db.surahs)..where(
                    (s) =>
                        s.number.equals(int.parse(star['target_id'] as String)),
                  ))
                  .getSingleOrNull() ==
              null) {
        throw const FormatException('Unknown starred surah.');
      }
    }
    return BackupPreview(
      data,
      added,
      same,
      conflicts,
      events,
      duplicate,
      await _settings(),
    );
  }

  Future<ImportResult> import(
    BackupPreview preview, {
    bool applySettings = false,
  }) async {
    // Review objects are not a trust boundary. Revalidate a detached snapshot
    // before opening the atomic merge, including exact allowed columns.
    final data = await normalizeBackup(preview.data);
    return db.transaction(() async {
      // Revalidate against the current library, inside the same transaction.
      final current = await _previewData(data);
      if (applySettings &&
          !_equal(current.settingsBefore, preview.settingsBefore)) {
        throw const FormatException(
          'Settings changed. Review the import again.',
        );
      }
      for (final passage in rows(data, 'passages')) {
        await _insert('saved_passages', passage);
      }
      for (final star in rows(data, 'stars')) {
        await _insert('favorites', star);
      }
      for (final day in rows(data, 'days')) {
        await _insert('daily_activity', {
          ...day,
          'played_wall_ms': 0,
          'qualified': 0,
        });
      }
      for (final session in rows(data, 'sessions')) {
        final passage = session['passage_id'] == null
            ? null
            : await (db.select(
                    db.savedPassages,
                  )..where((p) => p.id.equals(session['passage_id'] as String)))
                  .getSingleOrNull();
        await _insert('listening_sessions', {
          ...session,
          'played_wall_ms': 0,
          'passage_id': passage?.assetId == session['asset_id']
              ? passage?.id
              : null,
        });
      }
      final days = {for (final d in rows(data, 'days')) d['local_date']: d};
      for (final event in rows(data, 'events')) {
        final day = days[event['local_date']]!;
        await FoundationRepository(db).creditMeasuredInterval(
          eventId: event['id'] as String,
          sessionId: event['session_id'] as String,
          localDate: event['local_date'] as String,
          timezonePolicy: day['timezone_policy'] as String,
          wallMs: event['played_wall_ms'] as int,
          goalMs: day['goal_ms'] as int,
          utcMs: event['utc_ms'] as int,
        );
      }
      if (applySettings) {
        final settings = data['settings'] as BackupRow;
        await db.customStatement(
          'UPDATE app_settings SET theme=?,reduced_motion=?,network_policy=?,daily_goal_ms=?,aurora_enabled=?,updated_utc_ms=? WHERE id=1',
          [
            settings['theme'],
            settings['reduced_motion'],
            settings['network_policy'],
            settings['daily_goal_ms'],
            settings['aurora_enabled'],
            DateTime.now().toUtc().millisecondsSinceEpoch,
          ],
        );
        db.markTablesUpdated([db.appSettings]);
      }
      return ImportResult(
        current.newPassages,
        current.conflicts.length,
        current.newEvents,
      );
    });
  }

  Future<void> _insert(String table, BackupRow row) async {
    await db.customStatement(
      'INSERT OR IGNORE INTO $table (${row.keys.join(',')}) VALUES (${List.filled(row.length, '?').join(',')})',
      row.values.toList(),
    );
    db.markTablesUpdated([
      switch (table) {
        'saved_passages' => db.savedPassages,
        'favorites' => db.favorites,
        'daily_activity' => db.dailyActivity,
        'listening_sessions' => db.listeningSessions,
        _ => throw StateError('Unsupported metadata table'),
      },
    ]);
  }

  static bool _equal(BackupRow a, BackupRow b) =>
      a.length == b.length &&
      a.entries.every((entry) => b[entry.key] == entry.value);
}

// Column names are accepted only after exact-key validation below.
List<BackupRow> rows(Map<String, Object?> data, String key) =>
    (data[key] as List).cast<BackupRow>();

Variable<String> variable(Object? value) => Variable(value as String);

// Top-level isolation boundaries deliberately capture only transferable data,
// never a repository, native SQLite connection or a shared closure context.
Future<String> encodeBackup(Map<String, Object?> data) => Isolate.run(() {
  final records = [
    'recordings',
    'passages',
    'stars',
    'days',
    'sessions',
    'events',
  ].fold<int>(0, (total, key) => total + (data[key] as List).length);
  if (records > 200000) {
    throw const FormatException('Backup exceeds 200,000 records.');
  }
  final text = jsonEncode(data);
  if (utf8.encode(text).length > MetadataBackup.maxBytes) {
    throw const FormatException('Backup exceeds the 32 MB limit.');
  }
  return text;
});
Future<Map<String, Object?>> decodeBackup(String text) =>
    Isolate.run(() => validateBackup(text));
Future<Map<String, Object?>> normalizeBackup(Map<String, Object?> data) =>
    Isolate.run(() => validateBackup(jsonEncode(data)));

Map<String, Object?> validateBackup(String text) {
  Never invalid(String reason) => throw FormatException(reason);
  if (utf8.encode(text).length > MetadataBackup.maxBytes) {
    invalid('Backup exceeds 32 MB.');
  }
  final decoded = jsonDecode(text);
  BackupRow object(Object? value, Set<String> keys) {
    if (value is! Map<String, Object?> ||
        value.length != keys.length ||
        !keys.every(value.containsKey)) {
      invalid('Unexpected or missing backup fields.');
    }
    return Map<String, Object?>.of(value);
  }

  int integer(BackupRow row, String key, int min, int max) {
    final value = row[key];
    if (value is! int || value < min || value > max) invalid('Invalid $key.');
    return value;
  }

  String string(BackupRow row, String key, int max, {bool empty = false}) {
    final value = row[key];
    if (value is! String ||
        value.length > max ||
        (!empty && value.trim().isEmpty)) {
      invalid('Invalid $key.');
    }
    return value;
  }

  String id(BackupRow row, String key) {
    final value = string(row, key, 128);
    if (!RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(value)) {
      invalid('Invalid identity.');
    }
    return value;
  }

  void choice(BackupRow row, String key, Set<Object> choices) {
    if (!choices.contains(row[key])) invalid('Invalid $key.');
  }

  const epochMax = 253402300799999;
  const wallMax = 3155760000000; // 100 years; no unbounded integer arithmetic.
  final data = object(decoded, {
    'format',
    'version',
    'exported_utc_ms',
    'settings',
    'recordings',
    'passages',
    'stars',
    'days',
    'sessions',
    'events',
  });
  if (data['format'] != 'al-murajaah-metadata' || data['version'] != 1) {
    invalid('Unsupported backup format or version.');
  }
  integer(data, 'exported_utc_ms', 0, epochMax);
  final settings = object(data['settings'], MetadataBackup._settingKeys);
  choice(settings, 'theme', {'system', 'light', 'dark'});
  choice(settings, 'network_policy', {'wifi', 'any'});
  integer(settings, 'daily_goal_ms', 0, 14400000);
  for (final key in ['reduced_motion', 'aurora_enabled']) {
    integer(settings, key, 0, 1);
  }
  data['settings'] = settings;
  const fields = {
    'recordings': {'id', 'sha256', 'duration_ms'},
    'passages': {
      'id',
      'asset_id',
      'title',
      'start_ms',
      'end_ms',
      'repeat_mode',
      'play_count',
      'gap_ms',
      'speed',
      'note',
      'created_utc_ms',
      'updated_utc_ms',
    },
    'stars': {'type', 'target_id', 'created_utc_ms'},
    'days': {
      'local_date',
      'timezone_policy',
      'played_wall_ms',
      'goal_ms',
      'qualified',
    },
    'sessions': {
      'id',
      'asset_id',
      'passage_id',
      'started_utc_ms',
      'ended_utc_ms',
      'played_wall_ms',
      'speed',
      'completion_reason',
    },
    'events': {'id', 'session_id', 'local_date', 'played_wall_ms', 'utc_ms'},
  };
  var recordCount = 0;
  for (final entry in fields.entries) {
    final list = data[entry.key];
    if (list is! List) invalid('Invalid record list.');
    recordCount += list.length;
    if (recordCount > 200000) invalid('Backup exceeds 200,000 records.');
    data[entry.key] = list.map((row) => object(row, entry.value)).toList();
  }
  Map<String, BackupRow> indexed(String key, String field) {
    final result = <String, BackupRow>{};
    for (final row in rows(data, key)) {
      final value = string(row, field, 128);
      if (result.containsKey(value)) {
        invalid('Duplicate identity inside backup.');
      }
      result[value] = row;
    }
    return result;
  }

  final recordings = indexed('recordings', 'id');
  final passages = indexed('passages', 'id');
  final days = indexed('days', 'local_date');
  final sessions = indexed('sessions', 'id');
  indexed('events', 'id');
  for (final row in recordings.values) {
    id(row, 'id');
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(string(row, 'sha256', 64))) {
      invalid('Invalid recording digest.');
    }
    integer(row, 'duration_ms', 1, wallMax);
  }
  void speed(BackupRow row) {
    final value = row['speed'];
    if (value is! num || !value.isFinite || value < 0.5 || value > 2.2) {
      invalid('Invalid playback speed.');
    }
  }

  for (final row in passages.values) {
    if (!RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    ).hasMatch(id(row, 'id'))) {
      invalid('Invalid passage UUID.');
    }
    final recording = recordings[id(row, 'asset_id')];
    if (recording == null) invalid('Missing recording identity.');
    string(row, 'title', 256);
    if (row['note'] != null) string(row, 'note', 4000, empty: true);
    final start = integer(row, 'start_ms', 0, recording['duration_ms'] as int);
    integer(row, 'end_ms', start + 1000, recording['duration_ms'] as int);
    choice(row, 'repeat_mode', {'finite', 'continuous'});
    if (row['repeat_mode'] == 'finite') {
      integer(row, 'play_count', 1, 999);
    } else if (row['play_count'] != null) {
      invalid('Continuous passage has a count.');
    }
    choice(row, 'gap_ms', {0, 2000, 5000, 10000});
    speed(row);
    final created = integer(row, 'created_utc_ms', 0, epochMax);
    integer(row, 'updated_utc_ms', created, epochMax);
  }
  final starKeys = <String>{};
  for (final row in rows(data, 'stars')) {
    choice(row, 'type', {'surah', 'passage'});
    final target = id(row, 'target_id');
    if (!starKeys.add('${row['type']}/$target')) invalid('Duplicate star.');
    if (row['type'] == 'passage' && !passages.containsKey(target)) {
      invalid('Missing starred passage.');
    }
    if (row['type'] == 'surah' &&
        (int.tryParse(target) == null ||
            int.parse(target) < 1 ||
            int.parse(target) > 114 ||
            int.parse(target).toString() != target)) {
      invalid('Invalid starred surah.');
    }
    integer(row, 'created_utc_ms', 0, epochMax);
  }
  for (final row in days.values) {
    final date = string(row, 'local_date', 10);
    final parsed = DateTime.tryParse('${date}T00:00:00Z');
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) ||
        parsed == null ||
        parsed.toIso8601String().substring(0, 10) != date) {
      invalid('Invalid local date.');
    }
    string(row, 'timezone_policy', 128);
    final wall = integer(row, 'played_wall_ms', 0, wallMax);
    final goal = integer(row, 'goal_ms', 0, 14400000);
    final qualified = integer(row, 'qualified', 0, 1);
    if (qualified == 1 && (goal == 0 || wall < goal)) {
      invalid('Unmeasured goal qualification.');
    }
  }
  for (final row in sessions.values) {
    id(row, 'id');
    if (!recordings.containsKey(id(row, 'asset_id'))) {
      invalid('Missing session recording.');
    }
    if (row['passage_id'] != null) {
      final passage = passages[id(row, 'passage_id')];
      if (passage == null || passage['asset_id'] != row['asset_id']) {
        invalid('Session passage mismatch.');
      }
    }
    final started = integer(row, 'started_utc_ms', 0, epochMax);
    if (row['ended_utc_ms'] != null) {
      integer(row, 'ended_utc_ms', started, epochMax);
    }
    integer(row, 'played_wall_ms', 0, wallMax);
    speed(row);
    if (row['completion_reason'] != null) {
      string(row, 'completion_reason', 128, empty: true);
    }
  }
  final dayTotals = <String, int>{}, sessionTotals = <String, int>{};
  for (final row in rows(data, 'events')) {
    id(row, 'id');
    final session = sessions[id(row, 'session_id')];
    final date = string(row, 'local_date', 10);
    if (session == null || !days.containsKey(date)) {
      invalid('Missing activity reference.');
    }
    final wall = integer(row, 'played_wall_ms', 1, wallMax);
    integer(row, 'utc_ms', session['started_utc_ms'] as int, epochMax);
    dayTotals[date] = (dayTotals[date] ?? 0) + wall;
    sessionTotals[session['id'] as String] =
        (sessionTotals[session['id']] ?? 0) + wall;
  }
  for (final entry in days.entries) {
    if ((dayTotals[entry.key] ?? 0) != entry.value['played_wall_ms']) {
      invalid('Daily total does not match measured events.');
    }
  }
  for (final entry in sessions.entries) {
    if ((sessionTotals[entry.key] ?? 0) != entry.value['played_wall_ms']) {
      invalid('Session total does not match measured events.');
    }
  }
  return data;
}
