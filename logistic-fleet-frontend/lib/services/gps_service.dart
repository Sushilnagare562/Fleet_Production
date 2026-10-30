import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/gps_device.dart';

class GpsService {
  final _storage = const FlutterSecureStorage();
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _controller;

  Future<List<GpsDevice>> getDevices() async {
    final response = await ApiClient.instance.dio.get('/admin/devices');
    return (response.data as List).map((e) => GpsDevice.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<GpsDevice> addDevice({required String deviceId, required int vehicleId}) async {
    final response = await ApiClient.instance.dio.post('/admin/devices', data: {
      'deviceId': deviceId,
      'vehicleId': vehicleId,
    });
    return GpsDevice.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> removeDevice(int id) async {
    await ApiClient.instance.dio.delete('/admin/devices/$id');
  }

  /// Sends one fake telemetry reading through the same backend ingestion
  /// path a real MQTT device would use - handy for demoing/testing the
  /// live map before real hardware is connected.
  Future<void> simulateTelemetry({
    required String deviceId,
    required double lat,
    required double lng,
    double speedKmh = 0,
    double fuelPercent = 100,
    bool ignitionOn = true,
  }) async {
    await ApiClient.instance.dio.post('/admin/devices/simulate', data: {
      'deviceId': deviceId,
      'lat': lat,
      'lng': lng,
      'speedKmh': speedKmh,
      'fuelPercent': fuelPercent,
      'ignitionOn': ignitionOn,
    });
  }

  /// Opens the live-tracking WebSocket and returns a stream of decoded
  /// telemetry update JSON maps (one per device ping). Call [disconnect]
  /// when the tracking screen is disposed.
  Future<Stream<Map<String, dynamic>>> connect() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    final uri = Uri.parse('${AppConstants.wsBaseUrl}/ws/live-tracking?token=$token');

    _channel = WebSocketChannel.connect(uri);
    _controller = StreamController<Map<String, dynamic>>.broadcast();

    _channel!.stream.listen(
      (raw) {
        try {
          _controller?.add(jsonDecode(raw as String) as Map<String, dynamic>);
        } catch (_) {
          // ignore malformed frames
        }
      },
      onError: (_) => _controller?.close(),
      onDone: () => _controller?.close(),
    );

    return _controller!.stream;
  }

  void disconnect() {
    _channel?.sink.close();
    _controller?.close();
    _channel = null;
    _controller = null;
  }
}
