import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../domain/entities/distributore.dart';
import '../../domain/entities/filtri.dart';
import '../../domain/repositories/fuel_repository.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/cache_key_builder.dart';
import '../datasources/fuel_local_datasource.dart';
import '../datasources/fuel_remote_datasource.dart';

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
    );

    final cached = await _local.get(key);
    if (cached != null) return cached;

    try {
      final results = await _remote.getNearbyFuel(lat: lat, lon: lon, filtri: filtri);
      await _local.set(key, results);
      return results;
    } catch (e, st) {
      debugPrint('[FuelRepository] getNearbyFuel failed: $e\n$st');

      if (e is AppException) rethrow;

      final isNetwork = e is SocketException ||
          e is TimeoutException ||
          e is HttpException;

      throw AppException(
        isNetwork ? AppErrorType.erroreRete : AppErrorType.erroreServer,
        dettaglio: e.toString(),
      );
    }
  }
}
