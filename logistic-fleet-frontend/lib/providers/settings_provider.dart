import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../core/settings/settings_service.dart';

/// Holds the two user-controlled presentation preferences — theme mode and
/// app language — and persists them. Kept entirely separate from business /
/// API state (AuthProvider, TripProvider, ...) as the brief requires: changing
/// theme or language never touches business data or triggers a data re-fetch.
class SettingsProvider extends ChangeNotifier {
  final SettingsService _service;

  SettingsProvider({SettingsService? service})
      : _service = service ?? SettingsService();

  ThemeMode _themeMode = ThemeMode.system;

  /// null => "follow the system language" (default until a manual choice).
  /// A non-null Locale => the user picked a language explicitly.
  Locale? _locale;

  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get isLoaded => _loaded;

  /// The locale MaterialApp should use. When the user hasn't chosen one, we
  /// resolve the device language against our supported set, falling back to
  /// English — exactly the rule in the brief (7.7 / 7.12).
  Locale get effectiveLocale => _locale ?? _resolveSystemLocale();

  /// The user's explicit choice, or null when following the system.
  Locale? get selectedLocale => _locale;

  /// Loads persisted prefs. Call once at startup before/while building the app.
  Future<void> load() async {
    _themeMode = await _service.loadThemeMode();
    final code = await _service.loadLanguageCode();
    if (code != null) {
      _locale = Locale(code);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners(); // instant UI update, no restart
    await _service.saveThemeMode(mode);
  }

  /// One-click language switch. Updates the whole UI immediately and persists.
  Future<void> setLocale(Locale locale) async {
    if (_locale?.languageCode == locale.languageCode) return;
    _locale = locale;
    notifyListeners(); // instant UI update, no restart, no API calls
    await _service.saveLanguageCode(locale.languageCode);
  }

  Locale _resolveSystemLocale() {
    final systemLocales = PlatformDispatcher.instance.locales;
    for (final l in systemLocales) {
      final match = AppLocalizations.supportedLocales
          .where((s) => s.languageCode == l.languageCode);
      if (match.isNotEmpty) return match.first;
    }
    return const Locale('en');
  }
}
