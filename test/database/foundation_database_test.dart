import 'dart:io';

import 'package:al_murajaah/core/database/app_database.dart';
import 'package:al_murajaah/core/database/foundation_repository.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/foundation_fixture.dart';

Future<bool> workerCredit(FoundationRepository repo) =>
    repo.creditMeasuredInterval(
      eventId: 'concurrent-event',
      sessionId: 'fixture-session',
      localDate: '2026-10-02',
      timezonePolicy: 'fixed-at-credit:UTC',
      wallMs: 500,
      goalMs: 300000,
      utcMs: 2000,
    );

void main() {
  test(
    'all theme choices survive closing and reopening a file-backed worker',
    () async {
      final root = await Directory.systemTemp.createTemp('foundation-persist');
      final file = File('${root.path}/app.sqlite');
      try {
        for (final mode in ['light', 'dark', 'system']) {
          var db = AppDatabase.file(file);
          await FoundationRepository(db).saveTheme(mode);
          await db.close();
          db = AppDatabase.file(file);
          expect(await FoundationRepository(db).readTheme(), mode);
          await FoundationRepository(db).verifyIntegrity();
          await db.close();
        }
      } finally {
        await root.delete(recursive: true);
      }
    },
  );

  test(
    'repository preserves relational data and rejects unsafe writes',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = FoundationRepository(db);
      try {
        await repo.readTheme();
        await seedFoundationFixture(db);
        final saved = (await repo.passages()).single;
        expect(saved.startMs, 2000);
        expect(saved.endMs, 5000);
        expect(saved.playCount, 3);
        await expectLater(
          repo.savePassage(
            saved.toCompanion(true).copyWith(endMs: const Value(11000)),
          ),
          throwsA(isA<Exception>()),
        );
        await repo.savePassage(
          saved
              .toCompanion(true)
              .copyWith(
                title: const Value('Updated fixture'),
                playCount: const Value(10),
              ),
        );
        expect((await repo.passages()).single.title, 'Updated fixture');
        expect((await repo.passages()).single.playCount, 10);
        await expectLater(
          db.customStatement(
            "UPDATE saved_passages SET repeat_mode='continuous',play_count=3",
          ),
          throwsA(isA<Exception>()),
        );
        await expectLater(
          db.customStatement("UPDATE audio_assets SET sha256=?", ['b' * 64]),
          throwsA(isA<Exception>()),
        );
        await expectLater(
          db.customStatement("UPDATE downloads SET received_bytes=110"),
          throwsA(isA<Exception>()),
        );
        await expectLater(
          db.customStatement(
            "UPDATE playback_checkpoints SET source_position_ms=11000",
          ),
          throwsA(isA<Exception>()),
        );
        await expectLater(
          repo.setFavorite('surah', '115', true),
          throwsA(isA<Exception>()),
        );
        await expectLater(
          db.customStatement(
            "INSERT INTO audio_assets VALUES ('unknown-edition','missing',1,1,'https://example.invalid/fixture.mp3','audio/mpeg',NULL,NULL,NULL,'unavailable')",
          ),
          throwsA(isA<Exception>()),
        );
        await expectLater(
          db.customStatement("UPDATE downloads SET relative_path='../outside'"),
          throwsA(isA<Exception>()),
        );
        await repo.setFavorite('passage', fixturePassageId, true);
        expect(await db.select(db.favorites).get(), hasLength(1));
        await repo.deletePassage(fixturePassageId);
        expect(await db.select(db.favorites).get(), isEmpty);
        expect(
          (await db.select(db.playbackCheckpoints).getSingle()).passageId,
          isNull,
        );
        await repo.verifyIntegrity();
      } finally {
        await db.close();
      }
    },
  );

  test('shared UI and worker callbacks credit one idempotent interval exactly once', () async {
    final root = await Directory.systemTemp.createTemp('foundation-writer');
    final db = AppDatabase.file(File('${root.path}/app.sqlite'));
    final repo = FoundationRepository(db);
    try {
      await repo.readTheme();
      await seedFoundationFixture(db);
      final results = await Future.wait([
        workerCredit(repo),
        repo.inWorker(workerCredit),
        repo.inWorker(workerCredit),
      ]);
      expect(results.where((value) => value).length, 1);
      expect(
        (await db.select(db.dailyActivity).getSingle()).playedWallMs,
        1500,
      );
      expect(
        (await db.select(db.listeningSessions).getSingle()).playedWallMs,
        1500,
      );
      await expectLater(
        repo.creditMeasuredInterval(
          eventId: 'concurrent-event',
          sessionId: 'fixture-session',
          localDate: '2026-10-02',
          timezonePolicy: 'fixed-at-credit:UTC',
          wallMs: 999,
          goalMs: 300000,
          utcMs: 2000,
        ),
        throwsStateError,
      );
      await expectLater(
        repo.creditMeasuredInterval(
          eventId: 'bad',
          sessionId: 'missing',
          localDate: '2026-10-03',
          timezonePolicy: 'fixed-at-credit:UTC',
          wallMs: 10,
          goalMs: 300000,
          utcMs: 2000,
        ),
        throwsA(isA<Exception>()),
      );
      expect(
        await db.select(db.dailyActivity).get(),
        hasLength(1),
      ); // transaction rolled back
      await repo.verifyIntegrity();
    } finally {
      await db.close();
      await root.delete(recursive: true);
    }
  });
}
