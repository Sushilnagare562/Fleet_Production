import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';

class TripProvider extends ChangeNotifier {
  final TripService _tripService = TripService();

  List<Trip> _trips = [];
  bool _loading = false;
  String? _error;

  List<Trip> get trips => _trips;
  bool get loading => _loading;
  String? get error => _error;

  List<Trip> get activeTrips =>
      _trips.where((t) => t.status == 'ASSIGNED' || t.status == 'IN_PROGRESS').toList();

  List<Trip> get pastTrips =>
      _trips.where((t) => t.status == 'COMPLETED' || t.status == 'CANCELLED').toList();

  Future<void> loadMyTrips() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _trips = await _tripService.getMyTrips();
    } catch (e) {
      _error = ApiClient.errorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Trip?> updateStatus(int tripId, String status) async {
    try {
      final updated = await _tripService.updateStatus(tripId, status);
      final index = _trips.indexWhere((t) => t.id == tripId);
      if (index != -1) {
        _trips[index] = updated;
        notifyListeners();
      }
      return updated;
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      notifyListeners();
      return null;
    }
  }
}
