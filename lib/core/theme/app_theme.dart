import 'package:flutter/material.dart';

/// Canonical V1 palette. Decoration is kept separate from readable controls.
class AppPalette {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.text,
    required this.secondaryText,
    required this.action,
    required this.onAction,
    required this.accent,
    required this.onAccent,
    required this.atmosphere,
  });
  final Color background, surface, text, secondaryText;
  final Color action, onAction, accent, onAccent;
  final Color atmosphere;

  static const light = AppPalette(
    background: Color(0xfff7fbfc),
    surface: Color(0xffffffff),
    text: Color(0xff102333),
    secondaryText: Color(0xff4d6273),
    action: Color(0xff087c7b),
    onAction: Color(0xffffffff),
    accent: Color(0xffc74810),
    onAccent: Color(0xffffffff),
    atmosphere: Color(0xffe4f7f6),
  );
  static const dark = AppPalette(
    background: Color(0xff070b14),
    surface: Color(0xff101a2b),
    text: Color(0xfff3f7fa),
    secondaryText: Color(0xffb6c4d4),
    action: Color(0xff3fd1cf),
    onAction: Color(0xff102333),
    accent: Color(0xffffb28a),
    onAccent: Color(0xff102333),
    atmosphere: Color(0xff031342),
  );
}

abstract final class AppTheme {
  static ThemeData forBrightness(Brightness brightness) {
    final palette = brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: palette.action,
          brightness: brightness,
        ).copyWith(
          primary: palette.action,
          onPrimary: palette.onAction,
          secondary: palette.accent,
          onSecondary: palette.onAccent,
          surface: palette.surface,
          onSurface: palette.text,
          onSurfaceVariant: palette.secondaryText,
        );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: palette.background,
      textTheme: base.textTheme.apply(
        bodyColor: palette.text,
        displayColor: palette.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        foregroundColor: palette.text,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.action, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    );
  }
}
