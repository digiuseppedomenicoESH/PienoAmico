import '../entities/filtri.dart';
import '../entities/fuel_results.dart';
import '../repositories/fuel_repository.dart';

class GetNearbyFuelUseCase {
  final FuelRepository _repository;

  const GetNearbyFuelUseCase(this._repository);

  Future<FuelResults> call({
    required double lat,
    required double lon,
    required Filtri filtri,
  }) {
    assert(filtri.raggioMetri > 0 && filtri.raggioMetri <= 20000);
    return _repository.getNearbyFuel(lat: lat, lon: lon, filtri: filtri);
  }
}
