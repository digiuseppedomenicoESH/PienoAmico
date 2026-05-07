import '../entities/filtri.dart';
import '../entities/fuel_results.dart';

abstract interface class FuelRepository {
  Future<FuelResults> getNearbyFuel({
    required double lat,
    required double lon,
    required Filtri filtri,
  });
}
