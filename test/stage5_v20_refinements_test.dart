import 'dart:io';

import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:al_murajaah/core/database/app_database.dart';
import 'package:al_murajaah/core/theme/app_theme.dart';
import 'package:al_murajaah/core/theme/product_components.dart';
import 'package:al_murajaah/features/activity/activity_screen.dart';
import 'package:al_murajaah/features/catalog/catalog.dart';
import 'package:al_murajaah/features/product/duration_display.dart';
import 'package:al_murajaah/features/product/main_tab_pager.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('display boundaries never change the timestamp formatter', () {
    for (final entry in {
      0: '0 min',
      1: '<1 min',
      999: '<1 min',
      59999: '<1 min',
      60000: '1 min',
      119999: '1 min',
      503000: '8 min',
      3600000: '60 min',
    }.entries) {
      expect(listeningDuration(entry.key), entry.value);
    }
    for (final entry in {
      0: '0 sec',
      5000: '5 sec',
      59999: '59 sec',
      60000: '1 min',
      89999: '1 min',
      90000: '2 min',
      149999: '2 min',
      150000: '3 min',
      157000: '3 min',
    }.entries) {
      expect(passageLengthLabel(entry.key), entry.value);
    }
    expect(playbackTime(157000), '2:37');
    expect(playbackTime(5000), '0:05');
    expect(playbackTime(33000), '0:33');
    final spec = SessionSpec(
      assetId: 'fixture',
      durationMs: 600000,
      isPassage: true,
      startMs: 5000,
      endMs: 162000,
      playCount: 5,
    );
    expect(spec.lengthMs, 157000);
    expect(spec.startMs, 5000);
    expect(spec.relativeToSource(28000), 33000);
    expect(spec.playCount, 5);
  });

  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '1/10/110/114 badges share centered dimensions $brightness $scale',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.forBrightness(brightness),
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: const Scaffold(
                  body: Column(
                    children: [
                      SurahNumberBadge(1),
                      SurahNumberBadge(10),
                      SurahNumberBadge(110),
                      SurahNumberBadge(114),
                    ],
                  ),
                ),
              ),
            ),
          );
          final sizes = tester.getSize(find.byType(SurahNumberBadge).first);
          for (final number in [1, 10, 110, 114]) {
            final badge = find.widgetWithText(SurahNumberBadge, '$number');
            expect(tester.getSize(badge), sizes);
            expect(sizes.width, sizes.height);
            expect(sizes.width, 44 * scale);
            expect(
              (tester.getCenter(find.text('$number')) - tester.getCenter(badge))
                  .distance,
              lessThan(.01),
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'shared options box selects once, highlights, cancels and scrolls at 200%',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var value = 5, changes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: StatefulBuilder(
                builder: (context, refresh) => AppChoiceField<int>(
                  label: 'Repeats',
                  value: value,
                  options: const {
                    1: '1',
                    3: '3',
                    5: '5',
                    10: '10',
                    33: '33',
                    999: '999',
                    0: 'Continuous',
                    -2: 'Custom',
                  },
                  leading: RepeatCountIcon(value),
                  onChanged: (v) => refresh(() {
                    value = v!;
                    changes++;
                  }),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(AppChoiceField<int>));
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(changes, 0);
      await tester.tap(find.byType(AppChoiceField<int>));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(SimpleDialogOption, 'Custom'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        find.widgetWithText(SimpleDialogOption, 'Continuous'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(SimpleDialogOption, 'Custom'));
      await tester.pumpAndSettle();
      expect(value, -2);
      expect(changes, 1);
      expect(find.byType(SimpleDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'loop uses full large count beside icon and no count for Continuous',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RepeatCountIcon(5),
                RepeatCountIcon(999),
                RepeatCountIcon(null),
              ],
            ),
          ),
        ),
      );
      expect(find.text('5'), findsOneWidget);
      expect(find.text('999'), findsOneWidget);
      expect(find.byIcon(Icons.loop_rounded), findsNWidgets(3));
      final large = find.widgetWithText(RepeatCountIcon, '999');
      final icon = find.descendant(of: large, matching: find.byType(Icon));
      expect(
        tester.getTopLeft(find.text('999')).dx,
        greaterThan(tester.getTopRight(icon).dx),
      );
    },
  );

  test('absent Wi-Fi preference defaults off; stored/imported choices survive reopen', () async {
    final root = await Directory.systemTemp.createTemp('v20-default');
    final file = File('${root.path}/db.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    try {
      expect(
        (await db.select(db.appSettings).getSingle()).networkPolicy,
        'any',
      );
      await db.customStatement(
        "UPDATE app_settings SET network_policy='wifi',daily_goal_ms=123456 WHERE id=1",
      );
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      final retained = await db.select(db.appSettings).getSingle();
      expect(retained.networkPolicy, 'wifi');
      expect(retained.dailyGoalMs, 123456);
      await db.customStatement(
        "UPDATE app_settings SET network_policy='any' WHERE id=1",
      );
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      expect(
        (await db.select(db.appSettings).getSingle()).networkPolicy,
        'any',
      );
      await db.customStatement('DELETE FROM app_settings');
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      expect(
        (await db.select(db.appSettings).getSingle()).networkPolicy,
        'any',
      );
      expect(
        (await db.customSelect('pragma user_version').getSingle()).read<int>(
          'user_version',
        ),
        4,
      );
    } finally {
      await db.close();
      await root.delete(recursive: true);
    }
  });

  testWidgets(
    'main swipes retain scroll/input, preserve child drags and ignore Android edges',
    (tester) async {
      var index = 0;
      final input = TextEditingController();
      addTearDown(input.dispose);
      final homeScroll = ScrollController();
      addTearDown(homeScroll.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, refresh) => MainTabPager(
                index: index,
                onChanged: (next) => refresh(() => index = next),
                pages: [
                  ListView(
                    key: const PageStorageKey('home'),
                    controller: homeScroll,
                    children: [
                      TextField(controller: input),
                      for (var n = 0; n < 40; n++)
                        SizedBox(height: 70, child: Text('Home $n')),
                    ],
                  ),
                  ListView(
                    key: const PageStorageKey('surahs'),
                    children: [
                      for (var n = 0; n < 40; n++)
                        SizedBox(height: 70, child: Text('Surah $n')),
                    ],
                  ),
                  ListView(
                    children: [
                      const Text('Saved'),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var n = 0; n < 20; n++)
                              SizedBox(
                                width: 100,
                                height: 80,
                                child: Text('Child $n'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Center(child: Text('Activity')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'retained filter');
      tester.testTextInput.hide();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.dragFrom(const Offset(200, 400), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(index, 0);
      final offset = homeScroll.offset;
      expect(offset, greaterThan(0));
      await tester.dragFrom(const Offset(400, 240), const Offset(-250, 0));
      await tester.pumpAndSettle();
      expect(index, 1);
      await tester.dragFrom(const Offset(200, 240), const Offset(250, 0));
      await tester.pumpAndSettle();
      expect(index, 0);
      expect(homeScroll.offset, offset);
      expect(input.text, 'retained filter');
      await tester.dragFrom(const Offset(2, 240), const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(index, 0);
      for (var n = 0; n < 2; n++) {
        await tester.dragFrom(const Offset(400, 240), const Offset(-250, 0));
        await tester.pumpAndSettle();
      }
      expect(index, 2);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();
      expect(index, 2);
      await tester.dragFrom(const Offset(400, 240), const Offset(-250, 0));
      await tester.pumpAndSettle();
      expect(index, 3);
      expect(tester.takeException(), isNull);
    },
  );
}
