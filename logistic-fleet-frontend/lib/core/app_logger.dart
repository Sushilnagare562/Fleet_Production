import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Lightweight, centralized logger for the app.
///
/// Goals:
///  * One place to route all diagnostic output, so logging can later be
///    swapped for a remote crash/analytics sink (e.g. Crashlytics/Sentry)
///    without touching call sites.
///  * Debug/info/warning logs are emitted only in debug & profile builds, so
///    they never leak to end users' consoles in a release build.
///  * Errors are always recorded (even in release) so real production issues
///    remain traceable.
///
/// Usage:
///   AppLogger.i('Auth', 'User logged in');
///   AppLogger.e('Api', 'Request failed', error: e, stackTrace: st);
class AppLogger {
  AppLogger._();

  static const String _appName = 'LogisticFleet';

  static void d(String tag, String message) => _log(_Level.debug, tag, message);

  static void i(String tag, String message) => _log(_Level.info, tag, message);

  static void w(String tag, String message, {Object? error}) =>
      _log(_Level.warning, tag, message, error: error);

  static void e(String tag, String message, {Object? error, StackTrace? stackTrace}) =>
      _log(_Level.error, tag, message, error: error, stackTrace: stackTrace);

  static void _log(
    _Level level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Only errors are recorded in release builds; everything else is debug-only.
    if (!kDebugMode && level != _Level.error) return;

    developer.log(
      message,
      name: '$_appName/$tag',
      level: level.value,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

enum _Level {
  debug(500),
  info(800),
  warning(900),
  error(1000);

  const _Level(this.value);
  final int value;
}
