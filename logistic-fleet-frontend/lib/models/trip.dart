class RouteStop {
  final int? id;
  final String locationName;
  final double? latitude;
  final double? longitude;
  final String stopType; // PICKUP, DELIVERY, WAYPOINT
  final DateTime? plannedTime;
  final int? sequenceNo;

  RouteStop({
    this.id,
    required this.locationName,
    this.latitude,
    this.longitude,
    required this.stopType,
    this.plannedTime,
    this.sequenceNo,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      id: json['id'] as int?,
      locationName: json['locationName'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      stopType: json['stopType'] as String,
      plannedTime: json['plannedTime'] != null ? DateTime.parse(json['plannedTime']) : null,
      sequenceNo: json['sequenceNo'] as int?,
    );
  }
}

class TripStatusSummary {
  final int assigned;
  final int inProgress;
  final int completed;
  final int cancelled;
  final int total;

  TripStatusSummary({
    required this.assigned,
    required this.inProgress,
    required this.completed,
    required this.cancelled,
    required this.total,
  });

  factory TripStatusSummary.fromJson(Map<String, dynamic> json) {
    return TripStatusSummary(
      assigned: json['assigned'] as int,
      inProgress: json['inProgress'] as int,
      completed: json['completed'] as int,
      cancelled: json['cancelled'] as int,
      total: json['total'] as int,
    );
  }
}

class Trip {
  final int id;
  final String tripCode;
  final int? driverId;
  final String? driverName;
  final int? vehicleId;
  final String? vehicleNumber;
  final String origin;
  final String destination;
  final String status; // ASSIGNED, IN_PROGRESS, COMPLETED, CANCELLED
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final double? distanceKm;
  final String? notes;
  final List<RouteStop> routeStops;

  Trip({
    required this.id,
    required this.tripCode,
    this.driverId,
    this.driverName,
    this.vehicleId,
    this.vehicleNumber,
    required this.origin,
    required this.destination,
    required this.status,
    this.scheduledStart,
    this.scheduledEnd,
    this.actualStart,
    this.actualEnd,
    this.distanceKm,
    this.notes,
    this.routeStops = const [],
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as int,
      tripCode: json['tripCode'] as String,
      driverId: json['driverId'] as int?,
      driverName: json['driverName'] as String?,
      vehicleId: json['vehicleId'] as int?,
      vehicleNumber: json['vehicleNumber'] as String?,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      status: json['status'] as String,
      scheduledStart: json['scheduledStart'] != null ? DateTime.parse(json['scheduledStart']) : null,
      scheduledEnd: json['scheduledEnd'] != null ? DateTime.parse(json['scheduledEnd']) : null,
      actualStart: json['actualStart'] != null ? DateTime.parse(json['actualStart']) : null,
      actualEnd: json['actualEnd'] != null ? DateTime.parse(json['actualEnd']) : null,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      routeStops: (json['routeStops'] as List<dynamic>? ?? [])
          .map((e) => RouteStop.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
