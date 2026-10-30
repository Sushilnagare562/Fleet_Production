class AppUser {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final int? tenantId;
  final String? companyName;
  final String? profilePhoto;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.tenantId,
    this.companyName,
    this.profilePhoto,
  });

  factory AppUser.fromLoginJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['userId'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String,
      tenantId: json['tenantId'] as int?,
      companyName: json['companyName'] as String?,
    );
  }

  factory AppUser.fromProfileJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['userId'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String,
      tenantId: json['tenantId'] as int?,
      companyName: json['companyName'] as String?,
      profilePhoto: json['profilePhoto'] as String?,
    );
  }

  AppUser copyWith({
    String? name,
    String? phone,
    String? profilePhoto,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      tenantId: tenantId,
      companyName: companyName,
      profilePhoto: profilePhoto ?? this.profilePhoto,
    );
  }
}
