import '../../domain/entities/distributore.dart';
import '../../domain/entities/filtri.dart';
import '../../domain/repositories/fuel_repository.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/cache_key_builder.dart';
import '../datasources/fuel_local_datasource.dart';
import '../datasources/fuel_remote_datasource.dart';

// Implementazione concreta del repository.
// Orchestra cache locale e sorgente remota: cache-first, fallback su remoto.
class FuelRepositoryImpl implements FuelRepository {
  final FuelRemoteDatasource _remote;
  final FuelLocalDatasource  _local;

  const FuelRepositoryImpl(this._remote, this._local);

  @override
  Future<List<Distributore>> getNearbyFuel({
    required double lat,
    required double lon,
    required Filtri filtri,
  }) async {
    final key = CacheKeyBuilder.fuelResults(
      lat:         lat,
      lon:         lon,
      raggioMetri: filtri.raggioMetri,
      carburante:  filtri.carburante,
      isSelf:      filtri.isSelf,
    );

    // 1. Cache hit → restituisce subito
    final cached = await _local.get(key);
    if (cached != null) return cached;

    // 2. Fetch remoto
    try {
      final results = await _remote.getNearbyFuel(lat: lat, lon: lon, filtri: filtri);
      await _local.set(key, results);
      return results;
    } catch (e) {
      // 3. Se la rete fallisce e abbiamo una cache scaduta, la usiamo comunque
      final stale = await _local.get('$key\_stale');
      if (stale != null) return stale;
      throw AppException(AppErrorType.erroreRete, dettaglio: e.toString());
    }
  }
}
