import 'package:flutter/material.dart';

/// Selected means the durable write was acknowledged. On failure retain the
/// previous choice and report it; playback never depends on theme writes.
class AppearanceController extends ValueNotifier<ThemeMode> {
  AppearanceController({ThemeMode initial = ThemeMode.system, this.persist})
    : super(initial);
  final Future<void> Function(ThemeMode)? persist;
  bool saving = false;
  Object? saveError;

  Future<bool> select(ThemeMode choice) async {
    if (saving) return false;
    saving = true;
    saveError = null;
    notifyListeners();
    try {
      await persist?.call(choice);
      value = choice;
      return true;
    } catch (error) {
      saveError = error;
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
