import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_logger.dart';
import 'constants.dart';

/// Thin wrapper around Dio that automatically attaches the JWT bearer token
/// to every request and centralizes base URL / error handling.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          // Debug-only: trace every outgoing call. Bodies are intentionally not
          // logged to avoid leaking credentials/PII.
          AppLogger.d('Api', '→ ${options.method} ${options.uri.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.d(
            'Api',
            '← ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri.path}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          // Always recorded (even in release) so failing requests can be traced.
          final req = error.requestOptions;
          AppLogger.e(
            'Api',
            '✕ ${error.response?.statusCode ?? error.type.name} '
            '${req.method} ${req.uri.path} — ${error.message}',
            error: error,
          );
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  Dio get dio => _dio;

  /// Extracts a human-readable message from a DioException / backend error body.
  static String errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      if (data is Map && data['errors'] is Map) {
        final errors = (data['errors'] as Map).values.join(', ');
        return errors.isNotEmpty ? errors : 'Request failed';
      }
      return error.message ?? 'Network error. Please try again.';
    }
    return error.toString();
  }
}
