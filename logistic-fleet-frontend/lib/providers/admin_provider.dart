import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/driver.dart';
import '../models/route_optimization.dart';
import '../models/trip.dart';
import '../models/vehicle.dart';
import '../services/admin_driver_service.dart';
import '../services/route_optimization_service.dart';
import '../services/trip_service.dart';
import '../services/vehicle_service.dart';

class AdminProvider extends ChangeNotifier {
  final TripService _tripService = TripService();
  final AdminDriverService _driverService = AdminDriverService();
  final VehicleService _vehicleService = VehicleService();
  final RouteOptimizationService _routeOptimizationService = RouteOptimizationService();

  List<Trip> _allTrips = [];
  TripStatusSummary? _tripSummary;
  List<Driver> _drivers = [];
  List<Vehicle> _vehicles = [];

  bool _loading = false;
  String? _error;

  List<Trip> get allTrips => _allTrips;
  TripStatusSummary? get tripSummary => _tripSummary;
  List<Driver> get drivers => _drivers;
  List<Vehicle> get vehicles => _vehicles;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _tripService.getAllTrips(),
        _tripService.getStatusSummary(),
        _driverService.getAllDrivers(),
        _vehicleService.getAllVehicles(),
      ]);
      _allTrips = results[0] as List<Trip>;
      _tripSummary = results[1] as TripStatusSummary;
      _drivers = results[2] as List<Driver>;
      _vehicles = results[3] as List<Vehicle>;
    } catch (e) {
      _error = ApiClient.errorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadDrivers() async {
    try {
      _drivers = await _driverService.getAllDrivers();
      notifyListeners();
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      notifyListeners();
    }
  }

  Future<bool> createDriver({
    required String name,
    required String email,
    required String phone,
    required String temporaryPassword,
    String? vehicleNumber,
    String? licenseNumber,
  }) async {
    try {
      final driver = await _driverService.createDriver(
        name: name,
        email: email,
        phone: phone,
        temporaryPassword: temporaryPassword,
        vehicleNumber: vehicleNumber,
        licenseNumber: licenseNumber,
      );
      _drivers.insert(0, driver);
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// [status] must be 'ACTIVE' or 'ON_LEAVE'. Returns false (with [error] set) on failure.
  Future<bool> setDriverStatus(int driverId, String status) async {
    try {
      final updated = await _driverService.updateStatus(driverId, status);
      final index = _drivers.indexWhere((d) => d.id == driverId);
      if (index != -1) {
        _drivers[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Soft-deletes the driver and drops them from the local list on success.
  Future<bool> deleteDriver(int driverId) async {
    try {
      await _driverService.deleteDriver(driverId);
      _drivers.removeWhere((d) => d.id == driverId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> loadVehicles() async {
    try {
      _vehicles = await _vehicleService.getAllVehicles();
      notifyListeners();
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      notifyListeners();
    }
  }

  Future<bool> createVehicle({
    required String vehicleNumber,
    required String type,
    String? model,
    double? capacityKg,
    int? assignedDriverId,
  }) async {
    try {
      final vehicle = await _vehicleService.createVehicle(
        vehicleNumber: vehicleNumber,
        type: type,
        model: model,
        capacityKg: capacityKg,
        assignedDriverId: assignedDriverId,
      );
      _vehicles.insert(0, vehicle);
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> updateVehicleStatus(int vehicleId, String status) async {
    try {
      final updated = await _vehicleService.updateStatus(vehicleId, status);
      final index = _vehicles.indexWhere((v) => v.id == vehicleId);
      if (index != -1) {
        _vehicles[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      notifyListeners();
    }
  }

  Future<bool> assignTrip({
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
    try {
      final trip = await _tripService.assignTrip(
        driverId: driverId,
        vehicleId: vehicleId,
        origin: origin,
        destination: destination,
        scheduledStart: scheduledStart,
        scheduledEnd: scheduledEnd,
        distanceKm: distanceKm,
        notes: notes,
        routeStops: routeStops,
      );
      _allTrips.insert(0, trip);
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Asks the backend for the shortest order to visit [stops] in. Returns
  /// null (with [error] set) on failure so the caller can show a message
  /// without the whole dashboard re-rendering as an error state.
  Future<OptimizeRouteResult?> optimizeRoute({
    double? originLat,
    double? originLng,
    String? originLabel,
    required List<RouteStop> stops,
  }) async {
    try {
      final result = await _routeOptimizationService.optimizeRoute(
        originLat: originLat,
        originLng: originLng,
        originLabel: originLabel,
        stops: stops,
      );
      return result;
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      notifyListeners();
      return null;
    }
  }
}
