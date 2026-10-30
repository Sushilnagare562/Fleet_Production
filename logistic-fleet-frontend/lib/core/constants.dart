import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  AppConstants._();

  /// Backend base URL, adjusted automatically per platform so the same
  /// codebase works on Android emulator, iOS simulator, web, and physical
  /// devices without manual edits during local development.
  ///
  /// For a physical device or production deployment, replace
  /// [_productionBaseUrl] with your deployed backend's URL and flip
  /// [useProductionUrl] to true.
  static const String _productionBaseUrl = 'https://your-backend-domain.com/api';
  static const bool useProductionUrl = false;

  static String get baseUrl {
    if (useProductionUrl) return _productionBaseUrl;

    if (kIsWeb) {
      // Flutter web runs in the browser, so localhost resolves correctly.
      return 'http://localhost:8081/api';
    }
    if (Platform.isAndroid) {
      // 10.0.2.2 is the Android emulator's alias for the host machine.
      return 'http://10.0.2.2:8081/api';
    }
    // iOS simulator (and desktop) can reach the host machine via localhost.
    return 'http://localhost:8081/api';
  }

  /// Same host as [baseUrl] but ws:// scheme and no /api suffix, since the
  /// live-tracking socket is mounted at the server root (/ws/live-tracking).
  static String get wsBaseUrl {
    final http = baseUrl.replaceFirst('/api', '');
    return http.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
  }

  static const String tokenKey = 'logisticfleet_auth_token';
  static const String userNameKey = 'logisticfleet_user_name';
  static const String userEmailKey = 'logisticfleet_user_email';
  static const String userPhoneKey = 'logisticfleet_user_phone';
  static const String userRoleKey = 'logisticfleet_user_role';
  static const String userIdKey = 'logisticfleet_user_id';
  static const String tenantIdKey = 'logisticfleet_tenant_id';
  static const String companyNameKey = 'logisticfleet_company_name';
}
