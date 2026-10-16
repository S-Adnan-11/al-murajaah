import 'dart:io';
import 'dart:ui' as ui;

import 'package:al_murajaah/core/database/app_database.dart';
import 'package:al_murajaah/core/theme/app_theme.dart';
import 'package:al_murajaah/features/activity/activity_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final previewDate = DateTime(2026, 10, 9);
final previewDays = [
  const DailyActivityData(
    localDate: '2026-10-03',
    timezonePolicy: 'fixture',
    playedWallMs: 0,
    goalMs: 300000,
    qualified: 0,
  ),
  const DailyActivityData(
    localDate: '2026-10-07',
    timezonePolicy: 'fixture',
    playedWallMs: 300000,
    goalMs: 300000,
    qualified: 1,
  ),
  const DailyActivityData(
    localDate: '2026-10-08',
    timezonePolicy: 'fixture',
    playedWallMs: 360000,
    goalMs: 300000,
    qualified: 1,
  ),
  const DailyActivityData(
    localDate: '2026-10-09',
    timezonePolicy: 'fixture',
    playedWallMs: 91000,
    goalMs: 300000,
    qualified: 0,
  ),
];

Future<void> capture(WidgetTester tester, String name) async {
  final directory = Platform.environment['AL_MURAJAAH_UI_CAPTURES'];
  if (directory == null) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('preview-boundary')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(directory).create(recursive: true);
    await File('$directory/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fontDirectory = Platform.environment['AL_MURAJAAH_FONT_DIR'];
    if (fontDirectory != null) {
      final loader = FontLoader('Roboto');
      for (final font in [
        'roboto-regular.ttf',
        'roboto-medium.ttf',
        'roboto-bold.ttf',
      ]) {
        loader.addFont(
          File('$fontDirectory/$font')
              .readAsBytes()
              .then((value) => ByteData.sublistView(value)),
        );
      }
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          File('$fontDirectory/materialicons-regular.otf')
              .readAsBytes()
              .then((value) => ByteData.sublistView(value)),
        );
      await icons.load();
    }
  });

  for (final brightness in Brightness.values) {
    for (final populated in [false, true]) {
      testWidgets(
        'Activity ${populated ? 'populated' : 'empty'} summary and exact values in $brightness',
        (tester) async {
          tester.view.physicalSize = const Size(480, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          try {
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.forBrightness(brightness),
                home: RepaintBoundary(
                  key: const ValueKey('preview-boundary'),
                  child: Scaffold(
                    appBar: AppBar(title: const Text('Activity')),
                    body: ActivityOverview(
                      days: populated ? previewDays : [],
                      configuredGoalMs: 900000,
                      now: previewDate,
                      onGoalChanged: (_) {},
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final summary = find.byKey(
              const ValueKey('today-listening-summary'),
            );
            expect(
              find.descendant(
                of: summary,
                matching: find.text(populated ? '1 min' : '0 min'),
              ),
              findsOneWidget,
            );
            if (populated) {
              expect(find.text('5 min fulfillment'), findsOneWidget);
            } else {
              expect(find.text('15 min fulfillment'), findsOneWidget);
            }
            expect(
              find.bySemanticsLabel(
                RegExp(
                  'Friday.*October.*9.*today: ${populated ? '1 min' : '0 min'}',
                ),
              ),
              findsOneWidget,
            );
            await capture(
              tester,
              'activity-${populated ? 'populated' : 'empty'}-${brightness.name}-fixture',
            );
            await tester.scrollUntilVisible(
              find.text('Details'),
              180,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.ensureVisible(find.text('Details'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Details'));
            await tester.pumpAndSettle();
            final context = tester.element(find.byType(ActivityOverview));
            final missing =
                '${MaterialLocalizations.of(context).formatMediumDate(DateTime(2026, 10, 4))} · 0 min';
            await tester.scrollUntilVisible(
              find.text(missing),
              160,
              scrollable: find.byType(Scrollable).first,
            );
            expect(find.text(missing), findsOneWidget);
            if (populated) {
              final zero =
                  '${MaterialLocalizations.of(context).formatMediumDate(DateTime(2026, 10, 3))} · 0 min';
              expect(find.text(zero), findsOneWidget);
            }
            await tester.scrollUntilVisible(
              find.text('How listening time works'),
              160,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.ensureVisible(find.text('How listening time works'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('How listening time works'));
            await tester.pumpAndSettle();
            expect(
              find.textContaining('speed changes and seek jumps are excluded.'),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
}
