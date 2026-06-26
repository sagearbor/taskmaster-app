import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight app-wide theme mode controller, persisted with
/// shared_preferences. A single shared instance is wired into the MaterialApp
/// in both entry points (lib/main.dart and lib/main_mock.dart) and toggled
/// from the Settings screen. Defaults to [ThemeMode.system].
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const String _prefsKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  /// Load the persisted preference. Best-effort: never throws so it can be
  /// awaited during startup without risking a boot crash.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _themeMode = _decode(prefs.getString(_prefsKey));
      notifyListeners();
    } catch (_) {
      // Fall back to system default if storage is unavailable.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.name);
    } catch (_) {
      // Non-fatal: the in-memory change still applies for this session.
    }
  }

  static ThemeMode _decode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
