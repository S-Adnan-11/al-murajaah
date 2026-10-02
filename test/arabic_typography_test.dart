import 'package:al_murajaah/core/theme/arabic_name.dart';
import 'package:al_murajaah/core/theme/appearance_screen.dart';
import 'package:al_murajaah/core/theme/themed_app.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader(ArabicTypography.family)
      ..addFont(rootBundle.load(ArabicTypography.fontAsset));
    await loader.load();
  });

  test(
    'bundled Arabic font and redistributable license retain provenance',
    () async {
      final font = await rootBundle.load(ArabicTypography.fontAsset);
      expect(
        sha256.convert(font.buffer.asUint8List()).toString(),
        '63111b5b2e074dd48cc67692e0a2726d86ee94c1c37fe8598257b7b4e87e869e',
      );
      // GSUB/GPOS are the font's substitution/positioning tables. This checks
      // their presence; visual Arabic shaping still needs human review.
      final tables = <String>{};
      for (var i = 0; i < font.getUint16(4); i++) {
        tables.add(
          String.fromCharCodes([
            for (var j = 0; j < 4; j++) font.getUint8(12 + i * 16 + j),
          ]),
        );
      }
      expect(tables, containsAll(['cmap', 'GSUB', 'GPOS']));
      final license = await rootBundle.loadString(
        ArabicTypography.licenseAsset,
      );
      expect(license, contains('SIL OPEN FONT LICENSE Version 1.1'));
      expect(license, contains('Copyright 2022 The Noto Project Authors'));
      ArabicTypography.registerLicense();
      final entry = await LicenseRegistry.licenses
          .where((entry) => entry.packages.contains('Noto Sans Arabic'))
          .first;
      expect(
        entry.paragraphs.map((p) => p.text).join('\n'),
        contains('Version 1.1'),
      );
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('$brightness loaded Arabic preview and accessible controls', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(const ThemedApp(home: AppearanceScreen()));
        await tester.pumpAndSettle();
        final scroll = find
            .descendant(
              of: find.byKey(const ValueKey('appearance-content')),
              matching: find.byType(Scrollable),
            )
            .first;
        Future<void> guidelines() async {
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        }

        await guidelines();
        await tester.scrollUntilVisible(
          find.text('الفاتحة'),
          200,
          scrollable: scroll,
        );
        await tester.pumpAndSettle();
        final name = tester.widget<Text>(find.text('الفاتحة'));
        expect(name.textDirection, TextDirection.rtl);
        expect(name.locale, const Locale('ar'));
        expect(name.style?.fontFamily, ArabicTypography.family);
        expect(tester.getSemantics(find.text('الفاتحة')).label, 'الفاتحة');
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Font and software licenses'),
          200,
          scrollable: scroll,
        );
        await tester.pumpAndSettle();
        await guidelines();
        await tester.scrollUntilVisible(
          find.text('Controls'),
          200,
          scrollable: scroll,
        );
        await tester.pumpAndSettle();
        await guidelines();
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }
}
