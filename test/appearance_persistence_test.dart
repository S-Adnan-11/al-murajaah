import 'dart:async';

import 'package:al_murajaah/core/theme/appearance_controller.dart';
import 'package:al_murajaah/core/theme/appearance_screen.dart';
import 'package:al_murajaah/core/theme/themed_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'selection is acknowledged after persistence; failure retains choice and stays visible',
    (tester) async {
      var pending = Completer<void>();
      final controller = AppearanceController(persist: (_) => pending.future);
      await tester.pumpWidget(
        ThemedApp(home: const AppearanceScreen(), appearance: controller),
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Dark'));
      await tester.pump();
      expect(controller.value, ThemeMode.system);
      expect(find.text('Saving appearance…'), findsOneWidget);
      pending.completeError(StateError('disk full fixture'));
      await tester.pumpAndSettle();
      expect(controller.value, ThemeMode.system);
      expect(
        find.textContaining('Appearance could not be saved'),
        findsOneWidget,
      );
      pending = Completer<void>();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Light'));
      await tester.pump();
      pending.complete();
      await tester.pumpAndSettle();
      expect(controller.value, ThemeMode.light);
      expect(
        find.textContaining('Appearance could not be saved'),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
}
