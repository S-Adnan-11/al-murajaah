import 'package:al_murajaah/core/database/app_database.dart';
import 'package:al_murajaah/features/activity/activity_screen.dart';
import 'package:flutter_test/flutter_test.dart';

DailyActivityData day(String date, int ms, {int goalQualified = 0}) =>
    DailyActivityData(
      localDate: date,
      timezonePolicy: 'offset-at-credit-v1',
      playedWallMs: ms,
      goalMs: 300000,
      qualified: goalQualified,
    );
void main() {
  test('one-minute listening streak stays separate from recorded goal qualification', () {
    final today = DateTime(2026, 10, 9);
    final days = [
      day('2026-10-07', 60000),
      day('2026-10-08', 60001),
      day('2026-10-09', 59999),
    ];
    expect(currentListeningStreak(days, today), 2);
    expect(listeningStreak(days, today), 0);
    expect(
      currentListeningStreak([
        ...days.take(2),
        day('2026-10-09', 60000),
      ], today),
      3,
    );
    expect(
      currentListeningStreak([
        day('2026-10-07', 300000, goalQualified: 1),
      ], today),
      0,
    );
    expect(currentListeningStreak([], today), 0);
    expect(
      currentListeningStreak([
        day('2026-10-09', 60000),
        day('2026-10-07', 60000),
      ], today),
      1,
    );
  });
  test('calendar steps handle month/year, leap-day, DST and fixed recorded travel dates', () {
    expect(
      currentListeningStreak([
        day('2025-12-31', 60000),
        day('2026-01-01', 60000),
      ], DateTime(2026, 1, 1)),
      2,
    );
    expect(
      currentListeningStreak([
        day('2024-02-28', 60000),
        day('2024-02-29', 60000),
      ], DateTime(2024, 3, 1)),
      2,
    );
    expect(
      currentListeningStreak([
        day('2026-03-07', 60000),
        day('2026-03-08', 60000),
      ], DateTime(2026, 3, 9)),
      2,
    );
    expect(
      currentListeningStreak([
        day('2026-10-09', 60000),
      ], DateTime(2026, 10, 10)),
      1,
    );
    expect(
      currentListeningStreak([
        day('2026-10-09', 60000),
      ], DateTime(2026, 10, 11)),
      0,
    );
  });
}
