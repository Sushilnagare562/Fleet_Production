class Expense {
  final int? id;
  final int? tripId;
  final int? driverId;
  final String? driverName;
  final String category; // FUEL, TOLL, FOOD, MAINTENANCE, OTHER
  final double amount;
  final String? description;
  final String? receiptUrl;
  final DateTime expenseDate;
  final String status; // PENDING, APPROVED, REJECTED
  final String? reviewNotes;

  Expense({
    this.id,
    this.tripId,
    this.driverId,
    this.driverName,
    required this.category,
    required this.amount,
    this.description,
    this.receiptUrl,
    required this.expenseDate,
    this.status = 'PENDING',
    this.reviewNotes,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as int?,
      tripId: json['tripId'] as int?,
      driverId: json['driverId'] as int?,
      driverName: json['driverName'] as String?,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
      expenseDate: DateTime.parse(json['expenseDate']),
      status: json['status'] as String? ?? 'PENDING',
      reviewNotes: json['reviewNotes'] as String?,
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      if (tripId != null) 'tripId': tripId,
      'category': category,
      'amount': amount,
      if (description != null) 'description': description,
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
      'expenseDate': '${expenseDate.year.toString().padLeft(4, '0')}-'
          '${expenseDate.month.toString().padLeft(2, '0')}-'
          '${expenseDate.day.toString().padLeft(2, '0')}',
    };
  }
}
