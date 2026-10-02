import 'dart:io';

import 'package:al_murajaah/core/audio/prototype_store.dart';
import 'package:al_murajaah/core/audio/sample_catalog.dart';
import 'package:al_murajaah/core/audio/session_spec.dart';
import 'package:al_murajaah/core/theme/app_theme.dart';
import 'package:al_murajaah/core/theme/appearance_screen.dart';
import 'package:al_murajaah/core/theme/themed_app.dart';
import 'package:al_murajaah/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diagnostic_focus_test.dart' show FocusTestHandler;

void main() {
  testWidgets('appearance navigation and modes preserve session and B input', (
    tester,
  ) async {
    final root = await tester.runAsync(
      () => Directory.systemTemp.createTemp('murajaah_appearance'),
    );
    final handler = FocusTestHandler(PrototypeStore(root!));
    final spec = SessionSpec(assetId: samples.first.id, durationMs: 79263);
    handler.spec = spec;
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    try {
      await tester.pumpWidget(DiagnosticApp(handler: handler));
      await tester.pump();
      final endInput = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'B: source seconds',
      );
      await tester.enterText(endInput, '7.25');
      await tester.tap(find.byTooltip('Appearance'));
      await tester.pumpAndSettle();
      expect(find.byType(AppearanceScreen), findsOneWidget);
      expect(tester.testTextInput.isVisible, false);

      for (final choice in ['Light', 'Dark']) {
        await tester.tap(find.widgetWithText(ChoiceChip, choice));
        await tester.pumpAndSettle();
        final expected = choice == 'Light' ? Brightness.light : Brightness.dark;
        expect(
          Theme.of(tester.element(find.byType(AppearanceScreen))).brightness,
          expected,
        );
        expect(identical(handler.spec, spec), true);
        expect(handler.starts, 0);
        expect(handler.stops, 0);
      }
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.tap(find.widgetWithText(ChoiceChip, 'System'));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(AppearanceScreen))).brightness,
        Brightness.dark,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(DiagnosticScreen), findsOneWidget);
      expect(tester.widget<TextField>(endInput).controller!.text, '7.25');
      expect(
        Theme.of(tester.element(find.byType(DiagnosticScreen)))
            .colorScheme
            .primary,
        AppPalette.dark.action,
      );
      expect(handler.starts, 0);
      expect(handler.stops, 0);
      expect(identical(handler.spec, spec), true);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      handler.events.dispose();
      handler.revision.dispose();
      await tester.runAsync(() => root.delete(recursive: true));
    }
  });

  for (final brightness in Brightness.values) {
    test('$brightness review card and error colors remain readable', () {
      final palette = brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light;
      final colors = AppTheme.forBrightness(brightness).colorScheme;
      double ratio(Color a, Color b) {
        final first = a.computeLuminance();
        final second = b.computeLuminance();
        return first > second
            ? (first + 0.05) / (second + 0.05)
            : (second + 0.05) / (first + 0.05);
      }

      expect(
        ratio(palette.text, palette.atmosphere),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ratio(colors.onErrorContainer, colors.errorContainer),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ratio(colors.primary, palette.atmosphere),
        greaterThanOrEqualTo(3),
      );
    });
    testWidgets(
      '$brightness preview scrolls at 320px and 200% text without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(const ThemedApp(home: AppearanceScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final contentScroll = find
            .descendant(
              of: find.byKey(const ValueKey('appearance-content')),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.text('Controls'),
          250,
          scrollable: contentScroll,
        );
        await tester.pumpAndSettle();
        expect(find.text('Controls'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.textContaining('Example error:'),
          250,
          scrollable: contentScroll,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
