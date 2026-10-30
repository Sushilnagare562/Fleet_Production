class GpsDevice {
  final int id;
  final String deviceId;
  final int? vehicleId;
  final String? vehicleNumber;
  final String? driverName;
  double? lastLat;
  double? lastLng;
  double? lastSpeedKmh;
  double? lastFuelPercent;
  bool? ignitionOn;
  DateTime? lastSeenAt;
  bool online;

  GpsDevice({
    required this.id,
    required this.deviceId,
    this.vehicleId,
    this.vehicleNumber,
    this.driverName,
    this.lastLat,
    this.lastLng,
    this.lastSpeedKmh,
    this.lastFuelPercent,
    this.ignitionOn,
    this.lastSeenAt,
    this.online = false,
  });

  factory GpsDevice.fromJson(Map<String, dynamic> json) {
    return GpsDevice(
      id: json['id'] as int,
      deviceId: json['deviceId'] as String,
      vehicleId: json['vehicleId'] as int?,
      vehicleNumber: json['vehicleNumber'] as String?,
      driverName: json['driverName'] as String?,
      lastLat: (json['lastLat'] as num?)?.toDouble(),
      lastLng: (json['lastLng'] as num?)?.toDouble(),
      lastSpeedKmh: (json['lastSpeedKmh'] as num?)?.toDouble(),
      lastFuelPercent: (json['lastFuelPercent'] as num?)?.toDouble(),
      ignitionOn: json['ignitionOn'] as bool?,
      lastSeenAt: json['lastSeenAt'] != null ? DateTime.tryParse(json['lastSeenAt'] as String) : null,
      online: json['online'] as bool? ?? false,
    );
  }

  /// Applies a live telemetry update pushed over the WebSocket (see
  /// TelemetryUpdate on the backend) onto this device in place.
  void applyTelemetry(Map<String, dynamic> json) {
    lastLat = (json['lat'] as num?)?.toDouble() ?? lastLat;
    lastLng = (json['lng'] as num?)?.toDouble() ?? lastLng;
    lastSpeedKmh = (json['speedKmh'] as num?)?.toDouble() ?? lastSpeedKmh;
    lastFuelPercent = (json['fuelPercent'] as num?)?.toDouble() ?? lastFuelPercent;
    ignitionOn = json['ignitionOn'] as bool? ?? ignitionOn;
    lastSeenAt = json['timestamp'] != null ? DateTime.tryParse(json['timestamp'] as String) : DateTime.now();
    online = true;
  }

  bool get hasLocation => lastLat != null && lastLng != null;

  /// Running / Idle / Offline, matching what the map badge shows.
  String get statusLabel {
    if (!online) return 'Offline';
    if (ignitionOn == true && (lastSpeedKmh ?? 0) > 2) return 'Running';
    if (ignitionOn == true) return 'Idle';
    return 'Parked';
  }
}
