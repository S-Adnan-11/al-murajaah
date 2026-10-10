import 'dart:ui' as ui;

import 'package:al_murajaah/core/theme/product_components.dart';
import 'package:al_murajaah/core/database/app_database.dart';
import 'package:al_murajaah/core/theme/themed_app.dart';
import 'package:al_murajaah/features/activity/activity_screen.dart';
import 'package:al_murajaah/features/backup/backup_screen.dart';
import 'package:al_murajaah/features/backup/metadata_backup.dart';
import 'package:al_murajaah/features/product/aurora_backdrop.dart';
import 'package:al_murajaah/features/settings/product_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'metadata_backup_test.dart' show database;

Future<void> ready(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}

Widget large(Widget child) => ThemedApp(
  builder: (context, body) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: const TextScaler.linear(2), disableAnimations: true),
    child: body!,
  ),
  home: child,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const documents = MethodChannel('dev.almurajaah/metadata');
  void small(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> close(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(db.close);
  }

  testWidgets('Activity at 320px / 200% exposes totals and a labeled goal', (
    tester,
  ) async {
    small(tester);
    final db = (await tester.runAsync(database))!;
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        large(
          Scaffold(
            appBar: AppBar(title: const Text('Activity')),
            body: ActivityScreen(db: db),
          ),
        ),
      );
      await ready(tester);
      await tester.pumpAndSettle();
      expect(find.text('Today’s listening'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Daily details'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Daily details'));
      await tester.pumpAndSettle();
      expect(find.text('Daily details').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Daily details'));
      await tester.pumpAndSettle();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final label = MaterialLocalizations.of(
        tester.element(find.byType(ActivityScreen)),
      ).formatMediumDate(yesterday);
      await tester.scrollUntilVisible(
        find.text('$label · No recorded time'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('$label · 0 sec'), findsNothing);
      await tester.scrollUntilVisible(
        find.byType(AppChoiceField<int>),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Daily goal'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    } finally {
      semantics.dispose();
      await close(tester, db);
    }
  });
  testWidgets(
    'Settings at 320px / 200% retains motion choice and backup access',
    (tester) async {
      small(tester);
      final db = (await tester.runAsync(database))!;
      try {
        await tester.pumpWidget(
          large(ProductSettings(db: db, downloaded: () {})),
        );
        await ready(tester);
        await tester.pumpAndSettle();
        final reduce = find.widgetWithText(SwitchListTile, 'Reduce motion');
        await tester.scrollUntilVisible(
          reduce,
          140,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(reduce);
        await tester.pumpAndSettle();
        expect(reduce.hitTestable(), findsOneWidget);
        await tester.tap(reduce);
        await ready(tester);
        await tester.pumpAndSettle();
        final settings = await tester.runAsync(
          () => db.select(db.appSettings).getSingle(),
        );
        expect(settings!.reducedMotion, 1);
        await tester.scrollUntilVisible(
          find.text('Backup & restore'),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Backup & restore'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await close(tester, db);
      }
    },
  );
  testWidgets(
    'backup preview precedes import; cancel at large text preserves data',
    (tester) async {
      small(tester);
      final db = (await tester.runAsync(database))!;
      final text = (await tester.runAsync(() => MetadataBackup(db).export()))!;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            documents,
            (call) async => call.method == 'openBackup' ? text : false,
          );
      try {
        await tester.pumpWidget(
          large(BackupScreen(backup: MetadataBackup(db))),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Choose backup to import'),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('Choose backup to import'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Choose backup to import'));
        for (var i = 0; i < 30; i++) {
          await ready(tester);
          if (find.byType(LinearProgressIndicator).evaluate().isEmpty) break;
        }
        await tester.scrollUntilVisible(
          find.text('Review import'),
          160,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Review import'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Cancel import'),
          160,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('Cancel import'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancel import'));
        await tester.pumpAndSettle();
        expect(find.text('Review import'), findsNothing);
        final days = await tester.runAsync(
          () => db.select(db.dailyActivity).getSingle(),
        );
        expect(days!.playedWallMs, 1000);
      } finally {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(documents, null);
        await close(tester, db);
      }
    },
  );
  testWidgets(
    'aurora repaints without parent builds and stops for motion/background',
    (tester) async {
      final db = (await tester.runAsync(database))!;
      await tester.runAsync(
        () => db.customStatement('UPDATE app_settings SET aurora_enabled=1'),
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(documents, (call) async => false);
      var builds = 0;
      try {
        await tester.pumpWidget(
          ThemedApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(child: AuroraBackdrop(db: db, playing: true)),
                  Builder(
                    builder: (context) {
                      builds++;
                      return const Text('Stable player');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
        await ready(tester);
        final dynamic painter = tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(AuroraBackdrop),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter;
        final AnimationController animation =
            painter.animation as AnimationController;
        // The decoration must remain translucent at every point, with soft
        // ends; an opaque paint/vertex blend would hide the accepted gradient.
        await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          painter.paint(Canvas(recorder), const Size(240, 160));
          final picture = recorder.endRecording();
          final rendered = await picture.toImage(240, 160);
          final bytes = (await rendered.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          var maximumAlpha = 0;
          for (var offset = 3; offset < bytes.lengthInBytes; offset += 4) {
            if (bytes.getUint8(offset) > maximumAlpha) {
              maximumAlpha = bytes.getUint8(offset);
            }
          }
          expect(maximumAlpha, greaterThan(20));
          expect(maximumAlpha, lessThan(230));
          expect(bytes.getUint8(3), lessThan(10));
          rendered.dispose();
          picture.dispose();
        });
        await tester.pump(const Duration(seconds: 1));
        expect(animation.isAnimating, isTrue);
        expect(builds, 1);
        await tester.runAsync(() async {
          await db.customStatement('UPDATE app_settings SET reduced_motion=1');
          db.markTablesUpdated([db.appSettings]);
        });
        await ready(tester);
        await ready(tester);
        await tester.pump(const Duration(seconds: 1));
        expect(animation.isAnimating, isFalse);
        final still = animation.value;
        await tester.pump(const Duration(seconds: 1));
        expect(animation.value, still);
        await tester.runAsync(() async {
          await db.customStatement('UPDATE app_settings SET reduced_motion=0');
          db.markTablesUpdated([db.appSettings]);
        });
        await ready(tester);
        await ready(tester);
        await tester.pump(const Duration(seconds: 1));
        expect(animation.isAnimating, isTrue);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump(const Duration(seconds: 1));
        expect(animation.isAnimating, isFalse);
        expect(builds, 1);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      } finally {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(documents, null);
        await close(tester, db);
      }
    },
  );
}
