import 'package:al_murajaah/core/theme/themed_app.dart';
import 'package:al_murajaah/features/settings/product_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'metadata_backup_test.dart' show database;

void main() {
  testWidgets(
    'concise goal menu cancels safely and persists a selection without rewriting saved daily goals',
    (tester) async {
      final db = (await tester.runAsync(database))!;
      try {
        final previous = (await tester.runAsync(
          () => db.select(db.appSettings).getSingle(),
        ))!;
        final day = (await tester.runAsync(
          () => db.select(db.dailyActivity).getSingle(),
        ))!;
        await tester.pumpWidget(
          ThemedApp(
            home: ProductSettings(db: db, downloaded: () {}),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        final goal = find.widgetWithText(ListTile, 'Min. fulfillment');
        await tester.ensureVisible(goal);
        await tester.pumpAndSettle();
        await tester.tap(goal);
        await tester.pumpAndSettle();
        expect(find.text('Min. fulfillment'), findsNWidgets(2));
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          (await tester.runAsync(() => db.select(db.appSettings).getSingle()))!
              .dailyGoalMs,
          previous.dailyGoalMs,
        );
        await tester.tap(goal);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(SimpleDialogOption, '10 min'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        final selected = (await tester.runAsync(
          () => db.select(db.appSettings).getSingle(),
        ))!;
        expect(selected.dailyGoalMs, 600000);
        expect(selected.networkPolicy, previous.networkPolicy);
        expect(selected.reducedMotion, previous.reducedMotion);
        expect(
          await tester.runAsync(() => db.select(db.dailyActivity).getSingle()),
          day,
        );
        expect(find.text('10 min'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
        await tester.runAsync(db.close);
      }
    },
  );

  testWidgets('grouped Settings rows keep separate semantic touch bounds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = (await tester.runAsync(database))!;
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        ThemedApp(
          home: ProductSettings(db: db, downloaded: () {}),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      final tile = find.widgetWithText(ListTile, 'Theme');
      final node = tester.getSemantics(tile);
      expect(node.rect.height, greaterThanOrEqualTo(48));
      expect(node.rect.height, lessThanOrEqualTo(tester.getSize(tile).height));
      final motion = find.widgetWithText(SwitchListTile, 'Reduce motion');
      final motionNode = tester.getSemantics(motion);
      expect(
        motionNode.rect.height,
        lessThanOrEqualTo(tester.getSize(motion).height),
      );
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(db.close);
    }
  });
}
