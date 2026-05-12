import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../fuel/data/models/distributore_dto.dart';
import '../../../fuel/domain/entities/distributore.dart';

class TripRemoteDatasource {
  final SupabaseClient _client;

  TripRemoteDatasource(this._client);

  Future<List<Distributore>> getFuelAlongRoute({
    required List<LatLng> routePoints,
    required String carburante,
    int bufferM = 15000,
    int limit = 20,
  }) async {
    final sampled = _sample(routePoints, maxPoints: 60);

    final waypointsJson = sampled
        .map((p) => [p.latitude, p.longitude])
        .toList();

    final response = await _client.rpc('get_fuel_along_route', params: {
      'p_waypoints': waypointsJson,
      'p_carburante': carburante,
      'p_buffer_m': bufferM,
      'p_limit': limit,
    });

    return (response as List)
        .map((json) => DistributoreDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Prende al massimo maxPoints punti distribuiti uniformemente
  List<LatLng> _sample(List<LatLng> points, {required int maxPoints}) {
    if (points.length <= maxPoints) return points;
    final step = (points.length - 1) / (maxPoints - 1);
    return List.generate(
      maxPoints,
      (i) => points[(i * step).round().clamp(0, points.length - 1)],
    );
  }
}
