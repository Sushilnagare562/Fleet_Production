import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/user.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  /// Logs in with either the account's email or its registered mobile
  /// number. [identifier] is sent as-is; the backend figures out which one
  /// it is and normalizes it before lookup.
  Future<AppUser> login({required String identifier, required String password}) async {
    final response = await ApiClient.instance.dio.post('/auth/login', data: {
      'identifier': identifier,
      'password': password,
    });

    final data = response.data as Map<String, dynamic>;
    await _persistSession(data);
    return AppUser.fromLoginJson(data);
  }

  /// [companyName] identifies the tenant (transport company). If a company
  /// with that name already exists, the new user joins it; otherwise a
  /// brand-new tenant is created automatically. [role] must be one of
  /// 'ADMIN', 'DRIVER' or 'COMPANY_EMPLOYEE' — only the very first person
  /// to register a company name may register as ADMIN.
  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String companyName,
    required String role,
    String? vehicleNumber,
    String? licenseNumber,
  }) async {
    final response = await ApiClient.instance.dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'companyName': companyName,
      'role': role,
      if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
      if (licenseNumber != null) 'licenseNumber': licenseNumber,
    });

    final data = response.data as Map<String, dynamic>;
    await _persistSession(data);
    return AppUser.fromLoginJson(data);
  }

  Future<void> _persistSession(Map<String, dynamic> data) async {
    await _storage.write(key: AppConstants.tokenKey, value: data['token'] as String);
    await _storage.write(key: AppConstants.userNameKey, value: data['name'] as String);
    await _storage.write(key: AppConstants.userEmailKey, value: data['email'] as String);
    await _storage.write(key: AppConstants.userRoleKey, value: data['role'] as String);
    await _storage.write(key: AppConstants.userIdKey, value: (data['userId']).toString());
    if (data['phone'] != null) {
      await _storage.write(key: AppConstants.userPhoneKey, value: data['phone'] as String);
    }
    if (data['tenantId'] != null) {
      await _storage.write(key: AppConstants.tenantIdKey, value: (data['tenantId']).toString());
    }
    if (data['companyName'] != null) {
      await _storage.write(key: AppConstants.companyNameKey, value: data['companyName'] as String);
    }
  }

  Future<AppUser?> restoreSession() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token == null) return null;

    final name = await _storage.read(key: AppConstants.userNameKey);
    final email = await _storage.read(key: AppConstants.userEmailKey);
    final phone = await _storage.read(key: AppConstants.userPhoneKey);
    final role = await _storage.read(key: AppConstants.userRoleKey);
    final id = await _storage.read(key: AppConstants.userIdKey);
    final tenantId = await _storage.read(key: AppConstants.tenantIdKey);
    final companyName = await _storage.read(key: AppConstants.companyNameKey);

    if (name == null || email == null || role == null || id == null) return null;

    return AppUser(
      id: int.parse(id),
      name: name,
      email: email,
      phone: phone ?? '',
      role: role,
      tenantId: tenantId != null ? int.tryParse(tenantId) : null,
      companyName: companyName,
    );
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  /// Step 1 of "forgot password": backend emails a one-time verification
  /// code to the account's registered email, whether [identifier] is the
  /// account's email or its mobile number.
  Future<String> forgotPassword({required String identifier}) async {
    final response = await ApiClient.instance.dio.post('/auth/forgot-password', data: {
      'identifier': identifier,
    });
    return (response.data as Map<String, dynamic>)['message'] as String? ?? 'Verification code sent';
  }

  /// Step 2 of "forgot password": verify the code and set a new password.
  /// [identifier] must be the same email/mobile number submitted in step 1.
  Future<String> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
  }) async {
    final response = await ApiClient.instance.dio.post('/auth/reset-password', data: {
      'identifier': identifier,
      'otp': otp,
      'newPassword': newPassword,
    });
    return (response.data as Map<String, dynamic>)['message'] as String? ?? 'Password reset successfully';
  }

  /// Used from the Profile screen by an already-logged-in user.
  Future<String> changePassword({required String currentPassword, required String newPassword}) async {
    final response = await ApiClient.instance.dio.post('/profile/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    return (response.data as Map<String, dynamic>)['message'] as String? ?? 'Password changed successfully';
  }

  /// Fetches the full profile (including phone & photo) for the Profile tab.
  Future<AppUser> fetchProfile() async {
    final response = await ApiClient.instance.dio.get('/profile/me');
    final data = response.data as Map<String, dynamic>;
    if (data['phone'] != null) {
      await _storage.write(key: AppConstants.userPhoneKey, value: data['phone'] as String);
    }
    return AppUser.fromProfileJson(data);
  }

  /// Uploads/replaces the profile photo. [photoBase64] must NOT include the
  /// "data:image/...;base64," prefix.
  Future<AppUser> updateProfilePhoto(String photoBase64) async {
    final response = await ApiClient.instance.dio.put('/profile/photo', data: {
      'photoBase64': photoBase64,
    });
    return AppUser.fromProfileJson(response.data as Map<String, dynamic>);
  }
}
