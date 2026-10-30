class Earning {
  final int id;
  final int? tripId;
  final int? driverId;
  final String? driverName;
  final double baseAmount;
  final double bonus;
  final double deduction;
  final double totalAmount;
  final String status; // PENDING, PAID
  final DateTime? periodStart;
  final DateTime? periodEnd;

  Earning({
    required this.id,
    this.tripId,
    this.driverId,
    this.driverName,
    required this.baseAmount,
    required this.bonus,
    required this.deduction,
    required this.totalAmount,
    required this.status,
    this.periodStart,
    this.periodEnd,
  });

  factory Earning.fromJson(Map<String, dynamic> json) {
    return Earning(
      id: json['id'] as int,
      tripId: json['tripId'] as int?,
      driverId: json['driverId'] as int?,
      driverName: json['driverName'] as String?,
      baseAmount: (json['baseAmount'] as num).toDouble(),
      bonus: (json['bonus'] as num).toDouble(),
      deduction: (json['deduction'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'] as String,
      periodStart: json['periodStart'] != null ? DateTime.parse(json['periodStart']) : null,
      periodEnd: json['periodEnd'] != null ? DateTime.parse(json['periodEnd']) : null,
    );
  }
}

class EarningsSummary {
  final double totalEarned;
  final double totalPending;
  final double totalPaid;
  final int tripCount;

  EarningsSummary({
    required this.totalEarned,
    required this.totalPending,
    required this.totalPaid,
    required this.tripCount,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      totalEarned: (json['totalEarned'] as num).toDouble(),
      totalPending: (json['totalPending'] as num).toDouble(),
      totalPaid: (json['totalPaid'] as num).toDouble(),
      tripCount: json['tripCount'] as int,
    );
  }
}
