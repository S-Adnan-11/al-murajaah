import 'dart:io';

import 'package:al_murajaah/app/foundation_app.dart';
import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:al_murajaah/core/database/app_database.dart';
import 'package:al_murajaah/core/database/foundation_repository.dart';
import 'package:al_murajaah/core/theme/appearance_controller.dart';
import 'package:al_murajaah/core/theme/appearance_screen.dart';
import 'package:al_murajaah/core/theme/themed_app.dart';
import 'package:al_murajaah/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diagnostic_focus_test.dart' show FocusTestHandler;

void main() {
  testWidgets(
    'routed appearance retains editor and existing player; unknown route recovers',
    (tester) async {
      final root = await tester.runAsync(
        () => Directory.systemTemp.createTemp('foundation-route'),
      );
      final handler = FocusTestHandler(PrototypeStore(root!));
      final spec = SessionSpec(assetId: samples.first.id, durationMs: 79263);
      handler.spec = spec;
      final db = AppDatabase(NativeDatabase.memory());
      final appearance = AppearanceController();
      final deps = FoundationDependencies(
        db,
        FoundationRepository(db),
        appearance,
      );
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      try {
        await tester.pumpWidget(
          FoundationApp(handler: handler, dependencies: deps),
        );
        await tester.pumpAndSettle();
        final input = find.byWidgetPredicate(
          (w) =>
              w is TextField && w.decoration?.labelText == 'B: source seconds',
        );
        await tester.enterText(input, '7.25');
        await tester.tap(find.byTooltip('Appearance'));
        await tester.pumpAndSettle();
        expect(find.byType(AppearanceScreen), findsOneWidget);
        expect(tester.testTextInput.isVisible, false);
        await tester.tap(find.widgetWithText(ChoiceChip, 'Dark'));
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(input).controller!.text, '7.25');
        expect(identical(handler.spec, spec), true);
        expect(handler.starts, 0);
        expect(handler.stops, 0);
        final context = tester.element(find.byType(DiagnosticScreen));
        final router = ProviderScope.containerOf(context)
            .read(appRouterProvider);
        router.go('/missing');
        await tester.pumpAndSettle();
        expect(find.text('Page unavailable'), findsOneWidget);
        await tester.tap(find.text('Back to audio'));
        await tester.pumpAndSettle();
        expect(find.byType(DiagnosticScreen), findsOneWidget);
        expect(handler.starts, 0);
        expect(handler.stops, 0);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        handler.events.dispose();
        handler.revision.dispose();
        appearance.dispose();
        await tester.runAsync(() => db.close());
        await tester.runAsync(() => root.delete(recursive: true));
      }
    },
  );

  testWidgets(
    'bootstrap theme adopts restored controller without disposing it',
    (tester) async {
      const page = Scaffold(body: Text('Fixture'));
      await tester.pumpWidget(const ThemedApp(home: page));
      final restored = AppearanceController(initial: ThemeMode.dark);
      await tester.pumpWidget(ThemedApp(home: page, appearance: restored));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('Fixture'))).brightness,
        Brightness.dark,
      );
      await tester.pumpWidget(const SizedBox());
      expect(await restored.select(ThemeMode.light), true);
      restored.dispose();
    },
  );
}
