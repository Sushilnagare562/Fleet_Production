import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _user;
  AuthStatus _status = AuthStatus.unknown;
  String? _error;
  bool _loading = false;

  AppUser? get user => _user;
  AuthStatus get status => _status;
  String? get error => _error;
  bool get loading => _loading;
  bool get isAdmin => _user?.role == 'ADMIN';

  Future<void> restoreSession() async {
    final user = await _authService.restoreSession();
    _user = user;
    _status = user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
    if (user != null) {
      unawaited(NotificationService().initAfterLogin());
    }
  }

  /// Logs in with either the account's email or its registered mobile
  /// number — [identifier] is whatever the user typed in that single field.
  Future<bool> login(String identifier, String password) async {
    _setLoading(true);
    try {
      _user = await _authService.login(identifier: identifier, password: password);
      _status = AuthStatus.authenticated;
      _error = null;
      unawaited(NotificationService().initAfterLogin());
      return true;
    } catch (e) {
      _error = _friendlyError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String companyName,
    required String role,
    String? vehicleNumber,
    String? licenseNumber,
  }) async {
    _setLoading(true);
    try {
      _user = await _authService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        companyName: companyName,
        role: role,
        vehicleNumber: vehicleNumber,
        licenseNumber: licenseNumber,
      );
      _status = AuthStatus.authenticated;
      _error = null;
      unawaited(NotificationService().initAfterLogin());
      return true;
    } catch (e) {
      _error = _friendlyError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await NotificationService().unregister();
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Step 1 of "forgot password". [identifier] is the account's email or
  /// mobile number. Returns the backend's confirmation message on success;
  /// throws on failure (e.g. unregistered identifier) so the screen can
  /// show the error.
  Future<String> forgotPassword(String identifier) async {
    _setLoading(true);
    try {
      final message = await _authService.forgotPassword(identifier: identifier);
      _error = null;
      return message;
    } catch (e) {
      _error = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Step 2 of "forgot password": verify the emailed code and set a new
  /// password. [identifier] must match whatever was submitted in step 1.
  Future<String> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      final message =
          await _authService.resetPassword(identifier: identifier, otp: otp, newPassword: newPassword);
      _error = null;
      return message;
    } catch (e) {
      _error = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Used from the Profile screen by an already-logged-in user who knows
  /// their current password.
  Future<String> changePassword({required String currentPassword, required String newPassword}) async {
    _setLoading(true);
    try {
      final message = await _authService.changePassword(currentPassword: currentPassword, newPassword: newPassword);
      _error = null;
      return message;
    } catch (e) {
      _error = _friendlyError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Refreshes [user] with the full profile (including phone & photo) from
  /// the backend — call this when the Profile tab is opened.
  Future<void> refreshProfile() async {
    try {
      _user = await _authService.fetchProfile();
      notifyListeners();
    } catch (_) {
      // Non-fatal: keep showing whatever we already have cached locally.
    }
  }

  /// Uploads/replaces the profile photo and updates [user] on success.
  /// [photoBase64] must NOT include the "data:image/...;base64," prefix.
  Future<bool> updateProfilePhoto(String photoBase64) async {
    try {
      _user = await _authService.updateProfilePhoto(photoBase64);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  String _friendlyError(Object e) => ApiClient.errorMessage(e);
}
