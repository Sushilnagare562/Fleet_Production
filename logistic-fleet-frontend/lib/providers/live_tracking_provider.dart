import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/gps_device.dart';
import '../services/gps_service.dart';

class LiveTrackingProvider extends ChangeNotifier {
  final _gpsService = GpsService();
  StreamSubscription<Map<String, dynamic>>? _subscription;

  List<GpsDevice> _devices = [];
  bool _loading = false;
  bool _connected = false;
  String? _error;

  List<GpsDevice> get devices => _devices;
  bool get loading => _loading;
  bool get connected => _connected;
  String? get error => _error;
  int get onlineCount => _devices.where((d) => d.online).length;

  Future<void> start() async {
    await _loadDevices();
    await _connectLive();
  }

  Future<void> _loadDevices() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _devices = await _gpsService.getDevices();
    } catch (e) {
      _error = ApiClient.errorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _connectLive() async {
    try {
      final stream = await _gpsService.connect();
      _connected = true;
      notifyListeners();
      _subscription = stream.listen(
        _onTelemetry,
        onError: (_) {
          _connected = false;
          notifyListeners();
        },
        onDone: () {
          _connected = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _connected = false;
      notifyListeners();
    }
  }

  void _onTelemetry(Map<String, dynamic> update) {
    final deviceId = update['deviceId'] as String?;
    if (deviceId == null) return;

    final index = _devices.indexWhere((d) => d.deviceId == deviceId);
    if (index != -1) {
      _devices[index].applyTelemetry(update);
      notifyListeners();
    }
  }

  Future<void> addDevice({required String deviceId, required int vehicleId}) async {
    final device = await _gpsService.addDevice(deviceId: deviceId, vehicleId: vehicleId);
    _devices.add(device);
    notifyListeners();
  }

  Future<void> removeDevice(int id) async {
    await _gpsService.removeDevice(id);
    _devices.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  Future<void> simulateTelemetry(GpsDevice device, {required double lat, required double lng}) async {
    await _gpsService.simulateTelemetry(
      deviceId: device.deviceId,
      lat: lat,
      lng: lng,
      speedKmh: 35 + (DateTime.now().second % 30),
      fuelPercent: device.lastFuelPercent ?? 80,
      ignitionOn: true,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _gpsService.disconnect();
    super.dispose();
  }
}
