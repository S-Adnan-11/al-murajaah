import 'package:al_murajaah/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
}

void main() {
  for (final brightness in Brightness.values) {
    test('$brightness readable text and action palette meets 4.5:1', () {
      final palette = brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light;
      for (final background in [palette.background, palette.surface]) {
        expect(contrast(palette.text, background), greaterThanOrEqualTo(4.5));
        expect(
          contrast(palette.secondaryText, background),
          greaterThanOrEqualTo(4.5),
        );
      }
      expect(
        contrast(palette.onAction, palette.action),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(palette.onAccent, palette.accent),
        greaterThanOrEqualTo(4.5),
      );
      final theme = AppTheme.forBrightness(brightness);
      expect(theme.brightness, brightness);
      expect(theme.scaffoldBackgroundColor, palette.background);
      expect(theme.colorScheme.primary, palette.action);
      expect(theme.colorScheme.onSurface, palette.text);
    });
  }
}
