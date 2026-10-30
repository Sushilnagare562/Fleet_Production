import '../core/api_client.dart';
import '../models/route_optimization.dart';
import '../models/trip.dart';

class RouteOptimizationService {
  /// Calls the admin-only route optimizer. [stops] should include the
  /// origin/destination and any extra waypoints the dispatcher entered;
  /// stops missing lat/lng are still accepted but get placed last (they
  /// can't be reordered without coordinates).
  Future<OptimizeRouteResult> optimizeRoute({
    double? originLat,
    double? originLng,
    String? originLabel,
    required List<RouteStop> stops,
  }) async {
    final response = await ApiClient.instance.dio.post('/dispatch/route-optimize', data: {
      if (originLat != null) 'originLat': originLat,
      if (originLng != null) 'originLng': originLng,
      if (originLabel != null) 'originLabel': originLabel,
      'stops': stops
          .map((s) => {
                'locationName': s.locationName,
                'stopType': s.stopType,
                if (s.latitude != null) 'latitude': s.latitude,
                if (s.longitude != null) 'longitude': s.longitude,
                if (s.plannedTime != null) 'plannedTime': s.plannedTime!.toIso8601String(),
              })
          .toList(),
    });
    return OptimizeRouteResult.fromJson(response.data as Map<String, dynamic>);
  }
}
