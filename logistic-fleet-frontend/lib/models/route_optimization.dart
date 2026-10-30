import 'trip.dart';

class OptimizedStopResult {
  final RouteStop stop;
  final int sequenceNo;
  final double? legDistanceKm;

  OptimizedStopResult({
    required this.stop,
    required this.sequenceNo,
    this.legDistanceKm,
  });

  factory OptimizedStopResult.fromJson(Map<String, dynamic> json) {
    return OptimizedStopResult(
      stop: RouteStop.fromJson(json['stop'] as Map<String, dynamic>),
      sequenceNo: json['sequenceNo'] as int,
      legDistanceKm: (json['legDistanceKm'] as num?)?.toDouble(),
    );
  }
}

class OptimizeRouteResult {
  final List<OptimizedStopResult> orderedStops;
  final double totalDistanceKm;
  final int estimatedDurationMinutes;

  OptimizeRouteResult({
    required this.orderedStops,
    required this.totalDistanceKm,
    required this.estimatedDurationMinutes,
  });

  factory OptimizeRouteResult.fromJson(Map<String, dynamic> json) {
    return OptimizeRouteResult(
      orderedStops: (json['orderedStops'] as List<dynamic>)
          .map((e) => OptimizedStopResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
      estimatedDurationMinutes: json['estimatedDurationMinutes'] as int,
    );
  }
}
