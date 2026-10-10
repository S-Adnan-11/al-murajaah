import 'dart:convert';

import 'package:al_murajaah/core/theme/arabic_name.dart';
import 'package:al_murajaah/core/theme/themed_app.dart';
import 'package:al_murajaah/features/catalog/catalog.dart';
import 'package:al_murajaah/features/product_review/product_review.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalog catalog;
  late String source;
  setUpAll(() async {
    source = await rootBundle.loadString('assets/catalog/zarami.json');
    catalog = Catalog.parse(source);
    await (FontLoader(
      ArabicTypography.family,
    )..addFont(rootBundle.load(ArabicTypography.fontAsset))).load();
  });
  testWidgets(
    'review navigation/search and unavailable recording; no playback authority',
    (tester) async {
      // Keep the unavailable-state assertions with an explicit fixture rather
      // than depending on a production recording remaining defective.
      final fixture = jsonDecode(source) as Map<String, dynamic>;
      fixture['recordings'][40]['availability'] = 'unavailable';
      fixture['recordings'][40]['durationMs'] = null;
      fixture['recordings'][40]['unavailableReason'] = 'Recording under review';
      await tester.pumpWidget(
        ThemedApp(
          home: ProductReview(catalog: Catalog.parse(jsonEncode(fixture))),
        ),
      );
      await tester.ensureVisible(find.text('Continue passage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue passage'));
      await tester.pumpAndSettle();
      expect(find.text('Passage · 12:25–15:38'), findsOneWidget);
      expect(find.text('0:49'), findsOneWidget);
      expect(find.text('−2:24'), findsOneWidget);
      expect(
        find.text('Source position 13:14 · Passage length 3 min'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Close player'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Surahs'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '41');
      await tester.pumpAndSettle();
      expect(find.text('Recording under review'), findsOneWidget);
      tester.testTextInput.hide();
      await tester.ensureVisible(find.text('Fussilat'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fussilat'));
      await tester.pumpAndSettle();
      expect(find.text('Now listening'), findsNothing);
      await tester.enterText(find.byType(TextField), 'البقرة');
      await tester.pumpAndSettle();
      tester.testTextInput.hide();
      await tester.ensureVisible(find.text('Al-Baqarah'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Al-Baqarah'));
      await tester.pumpAndSettle();
      expect(find.text('Full surah'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final brightness in Brightness.values) {
    for (final page in ReviewPage.values) {
      testWidgets('$brightness $page at 320 px / 200% text', (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            ThemedApp(
              home: ProductReview(catalog: catalog, initialPage: page),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          if (page != ReviewPage.surahs) {
            await tester.drag(
              find.byType(ListView).first,
              const Offset(0, -1200),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
          }
        } finally {
          semantics.dispose();
        }
      });
    }
  }
}
