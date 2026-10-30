import '../core/api_client.dart';
import '../models/trip.dart';

class TripService {
  Future<List<Trip>> getMyTrips() async {
    final response = await ApiClient.instance.dio.get('/trips/my');
    return (response.data as List<dynamic>)
        .map((e) => Trip.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Trip> getTrip(int tripId) async {
    final response = await ApiClient.instance.dio.get('/trips/$tripId');
    return Trip.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Trip> updateStatus(int tripId, String status) async {
    final response = await ApiClient.instance.dio.patch(
      '/trips/$tripId/status',
      data: {'status': status},
    );
    return Trip.fromJson(response.data as Map<String, dynamic>);
  }

  // --- Admin / dispatch ---

  Future<List<Trip>> getAllTrips() async {
    final response = await ApiClient.instance.dio.get('/dispatch/trips');
    return (response.data as List<dynamic>)
        .map((e) => Trip.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TripStatusSummary> getStatusSummary() async {
    final response = await ApiClient.instance.dio.get('/dispatch/trips/summary');
    return TripStatusSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Trip> assignTrip({
    required int driverId,
    required int vehicleId,
    required String origin,
    required String destination,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    double? distanceKm,
    String? notes,
    List<RouteStop>? routeStops,
  }) async {
    final response = await ApiClient.instance.dio.post('/dispatch/trips', data: {
      'driverId': driverId,
      'vehicleId': vehicleId,
      'origin': origin,
      'destination': destination,
      if (scheduledStart != null) 'scheduledStart': scheduledStart.toIso8601String(),
      if (scheduledEnd != null) 'scheduledEnd': scheduledEnd.toIso8601String(),
      if (distanceKm != null) 'distanceKm': distanceKm,
      if (notes != null) 'notes': notes,
      if (routeStops != null)
        'routeStops': routeStops
            .asMap()
            .entries
            .map((entry) => {
                  'locationName': entry.value.locationName,
                  'stopType': entry.value.stopType,
                  'sequenceNo': entry.key + 1,
                  if (entry.value.plannedTime != null)
                    'plannedTime': entry.value.plannedTime!.toIso8601String(),
                })
            .toList(),
    });
    return Trip.fromJson(response.data as Map<String, dynamic>);
  }
}
