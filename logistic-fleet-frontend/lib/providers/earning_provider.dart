import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/earning.dart';
import '../services/earning_service.dart';

class EarningProvider extends ChangeNotifier {
  final EarningService _earningService = EarningService();

  List<Earning> _earnings = [];
  EarningsSummary? _summary;
  bool _loading = false;
  String? _error;

  List<Earning> get earnings => _earnings;
  EarningsSummary? get summary => _summary;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadMyEarnings() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _earningService.getMyEarnings(),
        _earningService.getMySummary(),
      ]);
      _earnings = results[0] as List<Earning>;
      _summary = results[1] as EarningsSummary;
    } catch (e) {
      _error = ApiClient.errorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // --- Admin ---

  List<Earning> _allEarnings = [];
  List<Earning> get allEarnings => _allEarnings;

  Future<void> loadAllEarnings() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _allEarnings = await _earningService.getAllEarnings();
    } catch (e) {
      _error = ApiClient.errorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createEarning({
    required int driverId,
    int? tripId,
    required double baseAmount,
    double? bonus,
    double? deduction,
  }) async {
    try {
      final earning = await _earningService.createEarning(
        driverId: driverId,
        tripId: tripId,
        baseAmount: baseAmount,
        bonus: bonus,
        deduction: deduction,
      );
      _allEarnings.insert(0, earning);
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> markPaid(int earningId) async {
    try {
      final updated = await _earningService.markPaid(earningId);
      final index = _allEarnings.indexWhere((e) => e.id == earningId);
      if (index != -1) {
        _allEarnings[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      notifyListeners();
    }
  }
}
