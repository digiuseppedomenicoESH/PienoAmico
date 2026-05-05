import '../entities/distributore.dart';
import '../entities/filtri.dart';

// Contratto astratto. L'implementazione concreta sta in data/repositories/.
// I provider Riverpod dipendono da questa interfaccia, non dall'implementazione.
abstract interface class FuelRepository {
  Future<List<Distributore>> getNearbyFuel({
    required double lat,
    required double lon,
    required Filtri filtri,
  });
}
