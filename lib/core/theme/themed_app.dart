import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'arabic_name.dart';
import 'appearance_controller.dart';

/// Appearance lives above navigation; changing it never recreates the player.
class ThemedApp extends StatefulWidget {
  const ThemedApp({super.key, required this.home, this.appearance})
    : router = null;
  const ThemedApp.router({
    super.key,
    required this.router,
    required this.appearance,
  }) : home = null;
  final Widget? home;
  final RouterConfig<Object>? router;
  final AppearanceController? appearance;

  @override
  State<ThemedApp> createState() => _ThemedAppState();
}

class _ThemedAppState extends State<ThemedApp> {
  late AppearanceController mode = widget.appearance ?? AppearanceController();
  late bool ownsMode = widget.appearance == null;

  @override
  void initState() {
    super.initState();
    ArabicTypography.registerLicense();
  }

  @override
  void didUpdateWidget(ThemedApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appearance != widget.appearance) {
      if (ownsMode) mode.dispose();
      mode = widget.appearance ?? AppearanceController();
      ownsMode = widget.appearance == null;
    }
  }

  @override
  void dispose() {
    if (ownsMode) mode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppearanceScope(
    mode: mode,
    child: ValueListenableBuilder<ThemeMode>(
      valueListenable: mode,
      builder: (context, value, _) => widget.router != null
          ? MaterialApp.router(
              title: "Al-Muraja'ah",
              debugShowCheckedModeBanner: false,
              theme: AppTheme.forBrightness(Brightness.light),
              darkTheme: AppTheme.forBrightness(Brightness.dark),
              themeMode: value,
              routerConfig: widget.router,
            )
          : MaterialApp(
              title: "Al-Muraja'ah",
              debugShowCheckedModeBanner: false,
              theme: AppTheme.forBrightness(Brightness.light),
              darkTheme: AppTheme.forBrightness(Brightness.dark),
              themeMode: value,
              home: widget.home,
            ),
    ),
  );
}

class AppearanceScope extends InheritedNotifier<AppearanceController> {
  const AppearanceScope({
    super.key,
    required AppearanceController mode,
    required super.child,
  }) : super(notifier: mode);

  static AppearanceController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppearanceScope>()!.notifier!;
}
