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
          secondaryContainer: brightness == Brightness.dark
              ? const Color(0xff943103)
              : const Color(0xffffe5d8),
          onSecondaryContainer: brightness == Brightness.dark
              ? const Color(0xfffff5ef)
              : const Color(0xff6b2607),
          surface: palette.surface,
          onSurface: palette.text,
          onSurfaceVariant: palette.secondaryText,
          primaryContainer: Color.lerp(palette.surface, palette.action, .06),
          onPrimaryContainer: palette.text,
          surfaceContainerLow: palette.surface,
          surfaceContainerHighest: Color.lerp(
            palette.surface,
            palette.text,
            .06,
          ),
          outline: Color.lerp(palette.surface, palette.secondaryText, .60),
          outlineVariant: Color.lerp(
            palette.surface,
            palette.secondaryText,
            .18,
          ),
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      fontFamilyFallback: const ['NotoSansArabic'],
    );
    return base.copyWith(
      scaffoldBackgroundColor: palette.background,
      textTheme: base.textTheme
          .copyWith(
            titleMedium: base.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            titleLarge: base.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            bodySmall: base.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              height: 1.45,
            ),
            bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.45),
          )
          .apply(bodyColor: palette.text, displayColor: palette.text),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: palette.text,
          fontWeight: FontWeight.w600,
          fontSize: 22,
          height: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.action, width: 2),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: palette.secondaryText,
        titleTextStyle: base.textTheme.bodyLarge?.copyWith(color: palette.text),
        subtitleTextStyle: base.textTheme.bodySmall?.copyWith(
          color: palette.secondaryText,
          height: 1.4,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide.none,
        backgroundColor: palette.surface,
        selectedColor: Color.lerp(palette.surface, palette.action, .20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: base.textTheme.labelLarge?.copyWith(color: palette.text),
      ),
      navigationBarTheme: NavigationBarThemeData(
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? palette.action
                : palette.secondaryText,
          ),
        ),
        backgroundColor: palette.surface,
        indicatorColor: Color.lerp(palette.surface, palette.action, .20),
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: .5,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xff203249)
            : const Color(0xffe4edf2),
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: palette.text,
        ),
        actionTextColor: brightness == Brightness.dark
            ? palette.accent
            : const Color(0xffad3b0b),
        closeIconColor: palette.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xff203249)
            : const Color(0xffe4edf2),
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: palette.text,
        ),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        shape: Border(),
        collapsedShape: Border(),
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
