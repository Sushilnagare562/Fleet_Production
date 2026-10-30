import '../core/api_client.dart';
import '../models/vehicle.dart';

class VehicleService {
  Future<List<Vehicle>> getAllVehicles() async {
    final response = await ApiClient.instance.dio.get('/admin/vehicles');
    return (response.data as List<dynamic>)
        .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Vehicle> createVehicle({
    required String vehicleNumber,
    required String type,
    String? model,
    double? capacityKg,
    int? assignedDriverId,
  }) async {
    final response = await ApiClient.instance.dio.post('/admin/vehicles', data: {
      'vehicleNumber': vehicleNumber,
      'type': type,
      if (model != null) 'model': model,
      if (capacityKg != null) 'capacityKg': capacityKg,
      if (assignedDriverId != null) 'assignedDriverId': assignedDriverId,
    });
    return Vehicle.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Vehicle> updateStatus(int vehicleId, String status) async {
    final response = await ApiClient.instance.dio.patch(
      '/admin/vehicles/$vehicleId/status',
      data: {'status': status},
    );
    return Vehicle.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Vehicle> assignDriver(int vehicleId, int? driverId) async {
    final response = await ApiClient.instance.dio.patch(
      '/admin/vehicles/$vehicleId/assign-driver',
      data: {'driverId': driverId},
    );
    return Vehicle.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteVehicle(int vehicleId) async {
    await ApiClient.instance.dio.delete('/admin/vehicles/$vehicleId');
  }
}
