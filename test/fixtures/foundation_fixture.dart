import 'package:drift/drift.dart';

const fixturePassageId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const fixtureHash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

/// Intentionally synthetic, unavailable for app playback. Never a production
/// catalog or an invented recording manifest. Works on schema snapshots too.
Future<void> seedFoundationFixture(GeneratedDatabase db) async {
  await db.customStatement(
    "INSERT INTO reciters VALUES ('fixture-reciter','Fixture',NULL,'Test only','No audio')",
  );
  await db.customStatement(
    "INSERT INTO surahs VALUES (1,'اختبار','Fixture','[\"test\"]')",
  );
  await db.customStatement(
    "INSERT INTO recording_editions VALUES ('fixture-edition','fixture-reciter','Hafs','Synthetic fixture')",
  );
  await db.customStatement(
    "INSERT INTO audio_assets VALUES ('fixture-asset','fixture-edition',1,1,'https://example.invalid/fixture.mp3','audio/mpeg',10000,111,?,'published')",
    [fixtureHash],
  );
  await db.customStatement(
    "INSERT INTO saved_passages VALUES (?,'fixture-asset','Fixture passage',2000,5000,'finite',3,0,1.0,'Fixture note',1000,1000)",
    [fixturePassageId],
  );
  await db.customStatement("INSERT INTO favorites VALUES ('passage',?,1000)", [
    fixturePassageId,
  ]);
  await db.customStatement(
    "INSERT INTO downloads VALUES ('fixture-asset','audio/fixture.mp3','fixture-task','verified',111,?,1000)",
    [fixtureHash],
  );
  await db.customStatement(
    "INSERT INTO playback_checkpoints VALUES ('fixture-session','passage','fixture-asset',?,2,1,3000,'{\"speed\":1.0}',1000)",
    [fixturePassageId],
  );
  await db.customStatement(
    "INSERT INTO listening_sessions VALUES ('fixture-session','fixture-asset',?,1000,NULL,1000,1.0,NULL)",
    [fixturePassageId],
  );
  await db.customStatement(
    "INSERT INTO daily_activity VALUES ('2026-10-02','fixed-at-credit:UTC',1000,300000,0)",
  );
  await db.customStatement(
    "INSERT INTO activity_events VALUES ('fixture-event','fixture-session','2026-10-02',1000,1000)",
  );
}
