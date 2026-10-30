class DockEvent {
  final int? id;
  final int tripId;
  final int? routeStopId;
  final String eventType; // DOCK_IN, DOCK_OUT
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final DateTime? eventTime;
  final String? remarks;

  DockEvent({
    this.id,
    required this.tripId,
    this.routeStopId,
    required this.eventType,
    this.locationName,
    this.latitude,
    this.longitude,
    this.eventTime,
    this.remarks,
  });

  factory DockEvent.fromJson(Map<String, dynamic> json) {
    return DockEvent(
      id: json['id'] as int?,
      tripId: json['tripId'] as int,
      routeStopId: json['routeStopId'] as int?,
      eventType: json['eventType'] as String,
      locationName: json['locationName'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      eventTime: json['eventTime'] != null ? DateTime.parse(json['eventTime']) : null,
      remarks: json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'tripId': tripId,
      if (routeStopId != null) 'routeStopId': routeStopId,
      'eventType': eventType,
      if (locationName != null) 'locationName': locationName,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (remarks != null) 'remarks': remarks,
    };
  }
}
