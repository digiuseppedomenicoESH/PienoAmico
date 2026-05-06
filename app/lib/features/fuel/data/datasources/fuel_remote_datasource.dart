import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/filtri.dart';
import '../../domain/entities/prezzo_record.dart';
import '../models/distributore_dto.dart';
import '../../../../features/fuel/domain/entities/distributore.dart';

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
      'p_limit':      30,
    });

    return (response as List)
        .map((json) => DistributoreDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<PrezzoRecord>> getStationPrices(int idImpianto) async {
    final response = await _client
        .from('prezzi_correnti')
        .select('carburante, is_self, prezzo, dt_comunicazione')
        .eq('id_impianto', idImpianto)
        .order('carburante');

    final map = <String, _Acc>{};
    for (final row in response as List) {
      final c    = row['carburante'] as String;
      final self = row['is_self'] as bool;
      final p    = (row['prezzo'] as num).toDouble();
      final dt   = DateTime.tryParse(row['dt_comunicazione'] as String? ?? '');
      final acc  = map[c] ??= _Acc(c);

      if (self) {
        acc.prezzoSelf = p;
      } else {
        acc.prezzoServito = p;
      }
      if (dt != null && (acc.dtUltima == null || dt.isAfter(acc.dtUltima!))) {
        acc.dtUltima = dt;
      }
    }

    return map.values
        .map((a) => PrezzoRecord(
              carburante:    a.carb,
              prezzoSelf:    a.prezzoSelf,
              prezzoServito: a.prezzoServito,
              dtUltima:      a.dtUltima,
            ))
        .toList()
      ..sort((a, b) => a.carburante.compareTo(b.carburante));
  }
}

class _Acc {
  final String carb;
  double? prezzoSelf;
  double? prezzoServito;
  DateTime? dtUltima;
  _Acc(this.carb);
}
