import 'dart:convert';

import 'package:al_murajaah/core/database/app_database.dart';
import 'package:al_murajaah/core/database/foundation_repository.dart';
import 'package:al_murajaah/features/backup/metadata_backup.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/foundation_fixture.dart';

Future<AppDatabase> database({bool empty = false}) async {
  final db = AppDatabase(NativeDatabase.memory());
  await FoundationRepository(db).readTheme();
  await seedFoundationFixture(db);
  if (empty) {
    for (final table in [
      'activity_events',
      'daily_activity',
      'listening_sessions',
      'playback_checkpoints',
      'favorites',
      'saved_passages',
    ]) {
      await db.customStatement('DELETE FROM $table');
    }
  }
  return db;
}

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });
  test('modified review data is fully revalidated before any merge', () async {
    final source = await database();
    final target = await database(empty: true);
    try {
      final backup = MetadataBackup(target);
      final preview = await backup.preview(
        await MetadataBackup(source).export(),
      );
      rows(preview.data, 'passages').first['untrusted_column'] = 'arbitrary';
      await expectLater(backup.import(preview), throwsFormatException);
      expect(await target.select(target.savedPassages).get(), isEmpty);
      expect(await target.select(target.dailyActivity).get(), isEmpty);
    } finally {
      await source.close();
      await target.close();
    }
  });
  test(
    'metadata round trip retains IDs/settings and excludes audio and paths',
    () async {
      final source = await database();
      final target = await database(empty: true);
      try {
        await source.customStatement(
          "UPDATE app_settings SET theme='dark',reduced_motion=1,aurora_enabled=1,daily_goal_ms=600000",
        );
        await source.customStatement('UPDATE saved_passages SET speed=2.2');
        final text = await MetadataBackup(source).export();
        expect(text, isNot(contains('https://')));
        expect(text, isNot(contains('relative_path')));
        expect(text, isNot(contains('native_task_id')));
        expect(text, isNot(contains('checkpoint')));
        final backup = MetadataBackup(target);
        final preview = await backup.preview(text);
        expect(preview.newPassages, 1);
        expect(preview.newEvents, 1);
        final result = await backup.import(preview, applySettings: true);
        expect(result.passages, 1);
        expect(result.events, 1);
        expect(
          (await target.select(target.savedPassages).getSingle()).id,
          fixturePassageId,
        );
        expect(
          (await target.select(target.savedPassages).getSingle()).speed,
          2.2,
        );
        expect(
          (await target.select(target.appSettings).getSingle()).theme,
          'dark',
        );
        expect(
          (await target.select(target.appSettings).getSingle()).reducedMotion,
          1,
        );
        expect(
          (await target.select(target.appSettings).getSingle()).auroraEnabled,
          1,
        );
        expect(
          (await target.select(target.dailyActivity).getSingle()).playedWallMs,
          1000,
        );
        expect(
          (await target.select(target.downloads).getSingle()).relativePath,
          'audio/fixture.mp3',
        );
        expect(
          (await target.select(target.favorites).getSingle()).targetId,
          fixturePassageId,
        );
        final exported = jsonDecode(await backup.export()) as Map;
        final original = jsonDecode(text) as Map;
        exported.remove('exported_utc_ms');
        original.remove('exported_utc_ms');
        expect(exported, original);
        await FoundationRepository(target).verifyIntegrity();
      } finally {
        await source.close();
        await target.close();
      }
    },
  );
  test(
    'repeated and concurrent imports cannot duplicate listening or saves',
    () async {
      final source = await database();
      final target = await database(empty: true);
      try {
        final backup = MetadataBackup(target);
        final preview = await backup.preview(
          await MetadataBackup(source).export(),
        );
        await Future.wait([backup.import(preview), backup.import(preview)]);
        await backup.import(
          await backup.preview(await MetadataBackup(source).export()),
        );
        expect(await target.select(target.savedPassages).get(), hasLength(1));
        expect(await target.select(target.activityEvents).get(), hasLength(1));
        expect(
          (await target.select(target.dailyActivity).getSingle()).playedWallMs,
          1000,
        );
        expect(
          (await target.select(target.listeningSessions).getSingle())
              .playedWallMs,
          1000,
        );
      } finally {
        await source.close();
        await target.close();
      }
    },
  );
  test(
    'conflicting passage retains owner version and settings default to keep',
    () async {
      final source = await database();
      final target = await database();
      try {
        await target.customStatement(
          "UPDATE saved_passages SET title='Owner edit',start_ms=3000",
        );
        await target.customStatement(
          "UPDATE app_settings SET theme='dark',network_policy='any'",
        );
        final backup = MetadataBackup(target);
        final preview = await backup.preview(
          await MetadataBackup(source).export(),
        );
        expect(preview.conflicts, hasLength(1));
        expect(preview.duplicateEvents, 1);
        final result = await backup.import(preview);
        expect(result.conflicts, 1);
        expect(result.events, 0);
        final passage = await target.select(target.savedPassages).getSingle();
        expect(passage.title, 'Owner edit');
        expect(passage.startMs, 3000);
        expect(
          (await target.select(target.appSettings).getSingle()).theme,
          'dark',
        );
        expect(
          (await target.select(target.appSettings).getSingle()).networkPolicy,
          'any',
        );
      } finally {
        await source.close();
        await target.close();
      }
    },
  );
  test(
    'late owner edit is rechecked; settings race requires fresh review',
    () async {
      final source = await database();
      final target = await database();
      try {
        final backup = MetadataBackup(target);
        final preview = await backup.preview(
          await MetadataBackup(source).export(),
        );
        await target.customStatement(
          "UPDATE saved_passages SET title='Newer owner edit'",
        );
        await target.customStatement(
          "UPDATE app_settings SET daily_goal_ms=60000",
        );
        await expectLater(
          backup.import(preview, applySettings: true),
          throwsFormatException,
        );
        final result = await backup.import(preview);
        expect(result.conflicts, 1);
        expect(
          (await target.select(target.savedPassages).getSingle()).title,
          'Newer owner edit',
        );
        expect(
          (await target.select(target.appSettings).getSingle()).dailyGoalMs,
          60000,
        );
      } finally {
        await source.close();
        await target.close();
      }
    },
  );
  test('failure after insertion rolls back the complete merge', () async {
    final source = await database();
    final target = await database(empty: true);
    try {
      final backup = MetadataBackup(target);
      final preview = await backup.preview(
        await MetadataBackup(source).export(),
      );
      await target.customStatement(
        "CREATE TRIGGER import_failure BEFORE INSERT ON favorites BEGIN SELECT RAISE(ABORT,'fixture failure'); END",
      );
      await expectLater(
        backup.import(preview, applySettings: true),
        throwsA(isA<Exception>()),
      );
      expect(await target.select(target.savedPassages).get(), isEmpty);
      expect(await target.select(target.activityEvents).get(), isEmpty);
      expect(await target.select(target.listeningSessions).get(), isEmpty);
      expect(await target.select(target.dailyActivity).get(), isEmpty);
      expect(await target.select(target.downloads).get(), hasLength(1));
    } finally {
      await source.close();
      await target.close();
    }
  });
  test(
    'malformed, unsafe, mismatched and fabricated input changes no data',
    () async {
      final db = await database();
      final backup = MetadataBackup(db);
      try {
        final text = await backup.export();
        final mutations = <void Function(Map<String, dynamic>)>[
          (d) => d['version'] = 99,
          (d) => d['audio_path'] = '../../private',
          (d) => d['passages'][0]['end_ms'] = 11000,
          (d) => d['passages'][0]['url'] = 'https://example.invalid/audio',
          (d) => d['passages'][0]['id'] = 'not-a-uuid',
          (d) => d['passages'].add(Map.of(d['passages'][0])),
          (d) => d['stars'][0]['target_id'] = 'missing',
          (d) => d['days'][0]['local_date'] = '2026-02-30',
          (d) => d['days'][0]['played_wall_ms'] = 3600000,
          (d) => d['days'][0]['qualified'] = 1,
          (d) => d['events'][0]['played_wall_ms'] = -1,
          (d) => d['events'][0]['session_id'] = 'missing',
          (d) => d['events'][0]['played_wall_ms'] = 2000,
          (d) => d['recordings'][0]['sha256'] = 'b' * 64,
          (d) => d['settings']['network_policy'] = 'arbitrary',
          (d) => d['settings']['daily_goal_ms'] = 1.5,
        ];
        for (final mutate in mutations) {
          final data = jsonDecode(text) as Map<String, dynamic>;
          mutate(data);
          await expectLater(
            backup.preview(jsonEncode(data)),
            throwsFormatException,
          );
          expect(
            (await db.select(db.dailyActivity).getSingle()).playedWallMs,
            1000,
          );
          expect(
            (await db.select(db.savedPassages).getSingle()).title,
            'Fixture passage',
          );
        }
        await expectLater(backup.preview('{broken'), throwsFormatException);
        final modified = jsonDecode(text) as Map<String, dynamic>;
        modified['events'][0]['utc_ms'] = 2000;
        await expectLater(
          backup.preview(jsonEncode(modified)),
          throwsFormatException,
          reason: 'same event ID with different payload',
        );
      } finally {
        await db.close();
      }
    },
  );
}
