class Vehicle {
  final int id;
  final String vehicleNumber;
  final String type; // TRUCK, VAN, BIKE, CAR, OTHER
  final String? model;
  final double? capacityKg;
  final String status; // ACTIVE, MAINTENANCE, INACTIVE
  final int? assignedDriverId;
  final String? assignedDriverName;

  Vehicle({
    required this.id,
    required this.vehicleNumber,
    required this.type,
    this.model,
    this.capacityKg,
    required this.status,
    this.assignedDriverId,
    this.assignedDriverName,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as int,
      vehicleNumber: json['vehicleNumber'] as String,
      type: json['type'] as String,
      model: json['model'] as String?,
      capacityKg: (json['capacityKg'] as num?)?.toDouble(),
      status: json['status'] as String,
      assignedDriverId: json['assignedDriverId'] as int?,
      assignedDriverName: json['assignedDriverName'] as String?,
    );
  }
}
