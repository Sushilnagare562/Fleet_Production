class Driver {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? vehicleNumber;
  final String? licenseNumber;
  final bool active;
  final String driverStatus; // ACTIVE, ON_LEAVE, DELETED
  final String role;

  Driver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.vehicleNumber,
    this.licenseNumber,
    required this.active,
    this.driverStatus = 'ACTIVE',
    required this.role,
  });

  bool get isOnLeave => driverStatus == 'ON_LEAVE';

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      vehicleNumber: json['vehicleNumber'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      active: json['active'] as bool,
      driverStatus: json['driverStatus'] as String? ?? 'ACTIVE',
      role: json['role'] as String,
    );
  }
}
