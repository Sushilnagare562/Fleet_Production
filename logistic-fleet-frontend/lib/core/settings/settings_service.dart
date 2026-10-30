import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight persistence for non-sensitive UI preferences (theme + language).
///
/// These are intentionally NOT stored in flutter_secure_storage — that is
/// reserved for the auth token / credentials. Theme and locale are plain
/// presentation prefs, so SharedPreferences is the right, lighter store and
/// works identically on Android, iOS and Web.
class SettingsService {
  static const _themeKey = 'logisticfleet_theme_mode';
  static const _localeKey = 'logisticfleet_locale';

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    switch (prefs.getString(_themeKey)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  /// Returns the persisted language code (e.g. 'hi'), or null if the user has
  /// never made a manual choice (so we can fall back to the system language).
  Future<String?> loadLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    return (code == null || code.isEmpty) ? null : code;
  }

  Future<void> saveLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, code);
  }
}
