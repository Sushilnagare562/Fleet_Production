import '../core/api_client.dart';
import '../models/dock_event.dart';

class DockService {
  Future<DockEvent> recordEvent(DockEvent event) async {
    final response = await ApiClient.instance.dio.post(
      '/dock-events',
      data: event.toRequestJson(),
    );
    return DockEvent.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<DockEvent>> getEventsForTrip(int tripId) async {
    final response = await ApiClient.instance.dio.get('/dock-events/trip/$tripId');
    return (response.data as List<dynamic>)
        .map((e) => DockEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
