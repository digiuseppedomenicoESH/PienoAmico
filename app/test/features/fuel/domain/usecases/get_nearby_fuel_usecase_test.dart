import 'package:flutter_test/flutter_test.dart';
import 'package:pienoamico/features/fuel/domain/entities/distributore.dart';
import 'package:pienoamico/features/fuel/domain/entities/filtri.dart';
import 'package:pienoamico/features/fuel/domain/repositories/fuel_repository.dart';
import 'package:pienoamico/features/fuel/domain/usecases/get_nearby_fuel_usecase.dart';

// Stub minimale del repository — nessun mock framework richiesto
class _FakeRepo implements FuelRepository {
  final List<Distributore> _fakeResults;
  _FakeRepo(this._fakeResults);

  @override
  Future<List<Distributore>> getNearbyFuel({
    required double lat,
    required double lon,
    required Filtri filtri,
  }) async => _fakeResults;
}

void main() {
  group('GetNearbyFuelUseCase', () {
    test('restituisce la lista dal repository', () async {
      const fakeDistributore = Distributore(
        id: 1, nome: 'Test', bandiera: 'Eni',
        indirizzo: 'Via Test 1', comune: 'Milano',
        isAutostradale: false, latitudine: 45.46, longitudine: 9.19,
        distanzaM: 500, prezzoSelf: 1.659,
      );
      final useCase = GetNearbyFuelUseCase(_FakeRepo([fakeDistributore]));

      final result = await useCase(
        lat: 45.46, lon: 9.19, filtri: const Filtri(),
      );

      expect(result, hasLength(1));
      expect(result.first.id, 1);
    });

    test('assert fallisce se raggio > 20000m', () {
      final useCase = GetNearbyFuelUseCase(_FakeRepo([]));
      expect(
        () => useCase(lat: 45.46, lon: 9.19, filtri: const Filtri(raggioMetri: 25000)),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
