import 'dart:convert';
import 'dart:io';

import 'package:al_murajaah/core/audio/prototype_handler.dart';
import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:al_murajaah/core/database/app_database.dart';
import 'package:al_murajaah/core/database/foundation_repository.dart';
import 'package:al_murajaah/core/theme/app_theme.dart';
import 'package:al_murajaah/core/theme/home_reading.dart';
import 'package:al_murajaah/core/theme/product_components.dart';
import 'package:al_murajaah/features/activity/activity_screen.dart';
import 'package:al_murajaah/features/backup/metadata_backup.dart';
import 'package:al_murajaah/features/catalog/catalog.dart';
import 'package:al_murajaah/features/support/confirmation_overlay.dart';
import 'package:al_murajaah/features/support/developer_screen.dart';
import 'package:al_murajaah/features/support/support_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_theme_test.dart' show contrast;
import 'post_v23_test.dart' show originDatabase;
import 'stage5_v19_playback_test.dart' show V19Player;
import 'stage5_v21_support_test.dart' show MemorySupportStore;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final brightness in Brightness.values) {
    testWidgets('repeat values retain placement and contrast in $brightness', (
      tester,
    ) async {
      for (final scale in [1.0, 2.0]) {
        for (final count in <int?>[1, 9, 10, 33, 99, 100, 999, null]) {
          final theme = AppTheme.forBrightness(brightness);
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Scaffold(body: Center(child: RepeatCountIcon(count))),
              ),
            ),
          );
          final icon = tester.widget<Icon>(find.byIcon(Icons.loop_rounded));
          expect(icon.color, theme.snackBarTheme.actionTextColor);
          expect(
            contrast(icon.color!, theme.colorScheme.primaryContainer),
            greaterThanOrEqualTo(4.5),
          );
          if (count != null) {
            final label = find.text('$count');
            expect(label, findsOneWidget);
            expect(tester.widget<Text>(label).style!.color, icon.color);
            final inStack = find.ancestor(
              of: label,
              matching: find.byType(Stack),
            );
            expect(inStack, count <= 99 ? findsOneWidget : findsNothing);
          } else {
            expect(find.byType(Text), findsNothing);
          }
          expect(tester.takeException(), isNull);
        }
      }
    });
  }
  test('paused checkpoint restoration does no native or file/network preparation; Play preserves progress', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.ryanheise.audio_session'),
          (_) async => null,
        );
    final root = await Directory.systemTemp.createTemp('final-restore');
    final store = PrototypeStore(root);
    final session = SessionSpec(
      assetId: 'zarami-hafs-001-v1',
      durationMs: 10000,
      startMs: 1000,
      endMs: 9000,
      playCount: 10,
      isPassage: true,
    );
    await store.checkpoint(session, 2, 2500);
    var resolves = 0;
    final player = V19Player();
    final handler = PrototypeHandler(
      store,
      player: player,
      localResolver: (_) async {
        resolves++;
        return null;
      },
    );
    try {
      await handler.initialize();
      expect(player.inspections, 0);
      expect(resolves, 0);
      expect(handler.restoredMetadata, true);
      expect(handler.playing, false);
      expect(handler.pass, 3);
      expect(handler.position.inMilliseconds, 2500);
      await handler.seek(const Duration(milliseconds: 3000));
      expect(player.inspections, 0);
      await handler.play();
      expect(player.inspections, 1);
      expect(handler.pass, 3);
      expect(handler.position.inMilliseconds, 3000);
      expect(handler.spec!.playCount, 10);
    } finally {
      await handler.dispose();
      await root.delete(recursive: true);
    }
  });

  test('best listening history merges dated runs, persists broken records and imports idempotently', () async {
    final source = await originDatabase();
    final target = await originDatabase();
    Future<void> credit(AppDatabase db, String date, String id) async {
      await db.customStatement(
        "INSERT OR IGNORE INTO listening_sessions (id,asset_id,started_utc_ms,speed) VALUES ('best-session','brother-001',0,1)",
      );
      await FoundationRepository(db).creditMeasuredInterval(
        eventId: id,
        sessionId: 'best-session',
        localDate: date,
        timezonePolicy: 'local-at-credit:UTC',
        wallMs: 1,
        goalMs: 300000,
        utcMs: 1,
      );
    }

    try {
      for (var day = 1; day <= 3; day++) {
        await credit(source, '2026-10-0$day', 'source-$day');
      }
      expect(
        (await source.select(source.listeningStreakRecords).getSingle())
            .bestDays,
        3,
      );
      final days = await source.select(source.dailyActivity).get();
      expect(currentListeningStreak(days, DateTime(2026, 10, 4)), 3);
      expect(currentListeningStreak(days, DateTime(2026, 10, 5)), 0);
      await saveDailyGoal(source, 0);
      expect(
        (await source.select(source.listeningStreakRecords).getSingle())
            .bestDays,
        3,
      );
      await credit(target, '2026-10-04', 'target-4');
      final backup = MetadataBackup(target);
      final text = await MetadataBackup(source).export();
      await backup.import(await backup.preview(text));
      await backup.import(await backup.preview(text));
      expect(
        (await target.select(target.listeningStreakRecords).getSingle())
            .bestDays,
        4,
      );
      expect(await target.select(target.activityEvents).get(), hasLength(4));
      await target.customStatement('DELETE FROM activity_events');
      await target.customStatement('DELETE FROM daily_activity');
      await target.reconcileBestListeningStreak();
      expect(
        (await target.select(target.listeningStreakRecords).getSingle())
            .bestDays,
        4,
      );
      final preserved = await MetadataBackup(target).export();
      expect(jsonDecode(preserved)['best_listening_streak'], 4);
      final legacy = jsonDecode(text) as Map<String, dynamic>;
      legacy['version'] = 2;
      legacy.remove('best_listening_streak');
      (legacy['settings'] as Map).remove('alternate_home_text');
      (legacy['settings'] as Map).remove('home_text_language');
      expect(await backup.preview(jsonEncode(legacy)), isNotNull);
    } finally {
      await source.close();
      await target.close();
    }
  });

  test('existing dates retain exact text and only dates receive italics', () {
    final span = storySpan(originStory);
    expect(span.toPlainText(), originStory);
    final dates = span.children!
        .whereType<TextSpan>()
        .where((s) => s.style?.fontStyle == FontStyle.italic)
        .map((s) => s.text)
        .toList();
    expect(dates, ['13.04.1448', '24.09.2026']);
  });

  test(
    'surah 3 uses the requested presentation with historical search aliases',
    () {
      final catalog = Catalog.parse(
        File('assets/catalog/zarami.json').readAsStringSync(),
      );
      expect(catalog.chapter(3).name, "Aali 'Imran");
      for (final query in [
        'Aal Imran',
        'Ali Imran',
        'Aali Imran',
        'Aal-e-Imran',
      ]) {
        expect(catalog.search(query).map((r) => r.number), contains(3));
      }
    },
  );

  for (final brightness in Brightness.values) {
    test(
      'error message surface and rust actions have readable contrast in $brightness',
      () {
        final theme = AppTheme.forBrightness(brightness);
        final background = theme.bannerTheme.backgroundColor!;
        expect(background, isNot(theme.scaffoldBackgroundColor));
        expect(background, isNot(theme.colorScheme.secondaryContainer));
        expect(
          contrast(theme.snackBarTheme.actionTextColor!, background),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(theme.bannerTheme.contentTextStyle!.color!, background),
          greaterThanOrEqualTo(4.5),
        );
      },
    );
  }

  testWidgets(
    'Home switches complete blocks, pauses offscreen and resumes without catch-up',
    (tester) async {
      final scroll = ScrollController();
      var active = true;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (_, set) {
              update = set;
              return Scaffold(
                body: ListView(
                  controller: scroll,
                  children: [
                    HomeReading(active: active, scroll: scroll),
                    const SizedBox(height: 1600),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 6500));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text(HomeReading.arabic.first), findsOneWidget);
      expect(find.text(HomeReading.english.first), findsNothing);
      update(() => active = false);
      await tester.pump();
      await tester.pump(const Duration(seconds: 20));
      expect(find.text(HomeReading.arabic.first), findsOneWidget);
      update(() => active = true);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      expect(find.text(HomeReading.arabic.first), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      scroll.dispose();
    },
  );

  testWidgets(
    'seven taps replay discovery, while remembered shortcut goes directly to story',
    (tester) async {
      final store = MemorySupportStore()..data['originDiscovered'] = true;
      await tester.pumpWidget(MaterialApp(home: DeveloperScreen(store: store)));
      await tester.pumpAndSettle();
      for (var i = 0; i < 7; i++) {
        await tester.tap(find.byKey(const ValueKey('developer-mark')));
        await tester.pump(const Duration(milliseconds: 60));
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(ConfirmationOverlay), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.byType(ConfirmationOverlay), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmationOverlay), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Where it began'));
      await tester.tap(find.text('Where it began'));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmationOverlay), findsNothing);
    },
  );
}
