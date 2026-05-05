import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/fuel_local_datasource.dart';
import '../../data/datasources/fuel_remote_datasource.dart';
import '../../data/repositories/fuel_repository_impl.dart';
import '../../domain/entities/distributore.dart';
import '../../domain/usecases/get_nearby_fuel_usecase.dart';
import 'filters_provider.dart';
import '../../../location/presentation/providers/location_provider.dart';

// Dependency wiring
final _remoteDsProvider = Provider(
  (ref) => FuelRemoteDatasource(Supabase.instance.client),
);
final _localDsProvider = Provider((ref) => FuelLocalDatasource());
final _repoProvider = Provider((ref) => FuelRepositoryImpl(
      ref.read(_remoteDsProvider),
      ref.read(_localDsProvider),
    ));
final _useCaseProvider = Provider(
  (ref) => GetNearbyFuelUseCase(ref.read(_repoProvider)),
);

// Provider principale: reagisce ai cambiamenti di posizione e filtri
final fuelResultsProvider = FutureProvider<List<Distributore>>((ref) async {
  final position = await ref.watch(locationProvider.future);
  final filtri   = ref.watch(filtriProvider);

  return ref.read(_useCaseProvider).call(
    lat:    position.latitude,
    lon:    position.longitude,
    filtri: filtri,
  );
});
