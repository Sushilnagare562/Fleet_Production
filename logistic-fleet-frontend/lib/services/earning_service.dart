import '../core/api_client.dart';
import '../models/earning.dart';

class EarningService {
  Future<List<Earning>> getMyEarnings() async {
    final response = await ApiClient.instance.dio.get('/earnings/my');
    return (response.data as List<dynamic>)
        .map((e) => Earning.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EarningsSummary> getMySummary() async {
    final response = await ApiClient.instance.dio.get('/earnings/my/summary');
    return EarningsSummary.fromJson(response.data as Map<String, dynamic>);
  }

  // --- Admin ---

  Future<List<Earning>> getAllEarnings() async {
    final response = await ApiClient.instance.dio.get('/admin/earnings');
    return (response.data as List<dynamic>)
        .map((e) => Earning.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Earning> createEarning({
    required int driverId,
    int? tripId,
    required double baseAmount,
    double? bonus,
    double? deduction,
  }) async {
    final response = await ApiClient.instance.dio.post('/admin/earnings', data: {
      'driverId': driverId,
      if (tripId != null) 'tripId': tripId,
      'baseAmount': baseAmount,
      if (bonus != null) 'bonus': bonus,
      if (deduction != null) 'deduction': deduction,
    });
    return Earning.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Earning> markPaid(int earningId) async {
    final response = await ApiClient.instance.dio.patch(
      '/admin/earnings/$earningId/status',
      data: {'status': 'PAID'},
    );
    return Earning.fromJson(response.data as Map<String, dynamic>);
  }
}
