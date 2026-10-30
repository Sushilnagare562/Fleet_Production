import '../core/api_client.dart';
import '../models/driver.dart';

class AdminDriverService {
  Future<List<Driver>> getAllDrivers() async {
    final response = await ApiClient.instance.dio.get('/admin/drivers');
    return (response.data as List<dynamic>)
        .map((e) => Driver.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Driver> createDriver({
    required String name,
    required String email,
    required String phone,
    required String temporaryPassword,
    String? vehicleNumber,
    String? licenseNumber,
  }) async {
    final response = await ApiClient.instance.dio.post('/admin/drivers', data: {
      'name': name,
      'email': email,
      'phone': phone,
      'temporaryPassword': temporaryPassword,
      if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
      if (licenseNumber != null) 'licenseNumber': licenseNumber,
    });
    return Driver.fromJson(response.data as Map<String, dynamic>);
  }

  /// [status] must be 'ACTIVE' or 'ON_LEAVE' - deleting goes through [deleteDriver] instead.
  Future<Driver> updateStatus(int driverId, String status) async {
    final response = await ApiClient.instance.dio.patch(
      '/admin/drivers/$driverId/status',
      data: {'status': status},
    );
    return Driver.fromJson(response.data as Map<String, dynamic>);
  }

  /// Soft-deletes the driver: their history is kept, but they drop off the driver list.
  Future<void> deleteDriver(int driverId) async {
    await ApiClient.instance.dio.delete('/admin/drivers/$driverId');
  }
}
