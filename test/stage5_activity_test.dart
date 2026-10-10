import 'dart:io';

import 'package:al_murajaah/core/database/app_database.dart';
import 'package:al_murajaah/core/database/foundation_repository.dart';
import 'package:al_murajaah/features/activity/activity_screen.dart';
import 'package:al_murajaah/features/activity/listening_recorder.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/foundation_fixture.dart';
import 'listening_meter_test.dart' show sample;

void main() {
  test(
    'failed activity write retains measured batch and retries once',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      await FoundationRepository(db).readTheme();
      await seedFoundationFixture(db);
      final recorder = ListeningRecorder(db);
      try {
        await db.customStatement(
          "CREATE TRIGGER blocked_credit BEFORE INSERT ON activity_events BEGIN SELECT RAISE(ABORT,'fixture disk failure'); END",
        );
        recorder.observe(sample(0, 0), 'fixture-asset', fixturePassageId);
        recorder.observe(sample(1000, 1000), 'fixture-asset', fixturePassageId);
        await recorder.flush();
        expect(recorder.error.value, isNotNull);
        expect(await db.select(db.activityEvents).get(), hasLength(1));
        await db.customStatement('DROP TRIGGER blocked_credit');
        await Future.wait([recorder.flush(), recorder.flush()]);
        expect(recorder.error.value, isNull);
        expect(await db.select(db.activityEvents).get(), hasLength(2));
        final days = await db.select(db.dailyActivity).get();
        expect(days.fold<int>(0, (total, d) => total + d.playedWallMs), 2000);
        await FoundationRepository(db).verifyIntegrity();
      } finally {
        await recorder.close();
        await db.close();
      }
    },
  );
  test(
    'bounded persisted increments, concurrent flush, reopen, no history',
    () async {
      final root = await Directory.systemTemp.createTemp('activity-v17');
      var db = AppDatabase.file(File('${root.path}/db.sqlite'));
      await FoundationRepository(db).readTheme();
      await seedFoundationFixture(db);
      await db.customStatement('DELETE FROM activity_events');
      await db.customStatement('DELETE FROM daily_activity');
      await db.customStatement('DELETE FROM listening_sessions');
      var recorder = ListeningRecorder(db);
      recorder.observe(
        sample(0, 0, length: 60000),
        'fixture-asset',
        fixturePassageId,
      );
      for (var i = 1; i <= 16; i++) {
        recorder.observe(
          sample(i * 1000, i * 1000, length: 60000),
          'fixture-asset',
          fixturePassageId,
        );
      }
      await Future.wait([recorder.flush(), recorder.flush(), recorder.flush()]);
      expect(
        (await db.select(db.dailyActivity).getSingle()).playedWallMs,
        16000,
      );
      expect(
        (await db.select(db.activityEvents).get()).length,
        lessThanOrEqualTo(2),
        reason: 'no per-position SQL events',
      );
      await recorder.close();
      await db.close();
      db = AppDatabase.file(File('${root.path}/db.sqlite'));
      recorder = ListeningRecorder(db);
      recorder.observe(
        sample(3600000, 5000),
        'fixture-asset',
        fixturePassageId,
      );
      await recorder.flush();
      expect(
        (await db.select(db.dailyActivity).getSingle()).playedWallMs,
        16000,
      );
      await recorder.close();
      await db.close();
      await root.delete(recursive: true);
    },
  );
  test('goal changes do not rewrite today or previous achievements', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await FoundationRepository(db).readTheme();
    await seedFoundationFixture(db);
    await saveDailyGoal(db, 1);
    await FoundationRepository(db).creditMeasuredInterval(
      eventId: 'new-goal-credit',
      sessionId: 'fixture-session',
      localDate: '2026-10-02',
      timezonePolicy: 'fixed-at-credit:UTC',
      wallMs: 60000,
      goalMs: 60000,
      utcMs: 2000,
    );
    var day = await db.select(db.dailyActivity).getSingle();
    expect(day.goalMs, 300000);
    expect(day.qualified, 0);
    await FoundationRepository(db).creditMeasuredInterval(
      eventId: 'future-day-credit',
      sessionId: 'fixture-session',
      localDate: '2026-10-03',
      timezonePolicy: 'fixed-at-credit:UTC',
      wallMs: 60000,
      goalMs: 60000,
      utcMs: 3000,
    );
    await saveDailyGoal(db, 30);
    final days = await db.select(db.dailyActivity).get();
    day = days.singleWhere((d) => d.localDate == '2026-10-03');
    expect(day.goalMs, 60000);
    expect(day.qualified, 1);
    expect(
      listeningStreak(days, DateTime(2026, 10, 4)),
      1,
      reason: 'unfinished today retains yesterday streak',
    );
    expect(listeningStreak(days, DateTime(2026, 10, 5)), 0);
    await db.close();
  });
  test(
    'goal Off never qualifies; deleting active passage cannot stop credit',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      await FoundationRepository(db).readTheme();
      await seedFoundationFixture(db);
      await saveDailyGoal(db, 0);
      final recorder = ListeningRecorder(db);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      recorder.observe(sample(0, 0), 'fixture-asset', fixturePassageId);
      recorder.observe(sample(1000, 1000), 'fixture-asset', fixturePassageId);
      await FoundationRepository(db).deletePassage(fixturePassageId);
      await recorder.flush();
      final days = await db.select(db.dailyActivity).get();
      final day = days.singleWhere((d) => d.localDate != '2026-10-02');
      expect(day.goalMs, 0);
      expect(day.qualified, 0);
      expect(day.playedWallMs, 1000);
      expect(recorder.error.value, isNull);
      await recorder.close();
      await db.close();
    },
  );
}
