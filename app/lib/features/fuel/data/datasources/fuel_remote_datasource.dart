import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/filtri.dart';
import '../models/distributore_dto.dart';
import '../../../../features/fuel/domain/entities/distributore.dart';

// Responsabile esclusivamente della comunicazione con Supabase.
// Non conosce la cache, non contiene logica di business.
class FuelRemoteDatasource {
  final SupabaseClient _client;

  FuelRemoteDatasource(this._client);

  Future<List<Distributore>> getNearbyFuel({
    required double lat,
    required double lon,
    required Filtri filtri,
  }) async {
    final response = await _client.rpc('get_nearby_fuel', params: {
      'p_lat':        lat,
      'p_lon':        lon,
      'p_raggio_m':   filtri.raggioMetri,
      'p_carburante': filtri.carburante,
      'p_is_self':    filtri.isSelf,
      'p_limit':      30,
    });

    return (response as List)
        .map((json) => DistributoreDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
