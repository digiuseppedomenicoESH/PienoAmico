import '../entities/distributore.dart';
import '../entities/filtri.dart';
import '../repositories/fuel_repository.dart';

// Use case: unico punto d'ingresso per la logica "trova carburante vicino".
// Aggiunge validazione di dominio che non appartiene né al repository né alla UI.
class GetNearbyFuelUseCase {
  final FuelRepository _repository;

  const GetNearbyFuelUseCase(this._repository);

  Future<List<Distributore>> call({
    required double lat,
    required double lon,
    required Filtri filtri,
  }) {
    assert(filtri.raggioMetri > 0 && filtri.raggioMetri <= 20000);
    return _repository.getNearbyFuel(lat: lat, lon: lon, filtri: filtri);
  }
}
