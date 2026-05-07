import 'package:hive/hive.dart';

import '../../domain/entities/distributore.dart';
import '../../domain/entities/fuel_results.dart';
import '../models/distributore_dto.dart';

class FuelLocalDatasource {
  static const _boxName = 'fuel_cache';
  static const _ttl = Duration(minutes: 90);

  Future<Box> get _box async => Hive.openBox(_boxName);

  Future<FuelResults?> get(String key) async {
    final box = await _box;
    try {
      final entry = box.get(key) as Map?;
      if (entry == null) return null;

      final cachedAt = DateTime.parse(entry['cached_at'] as String);
      if (DateTime.now().difference(cachedAt) >= _ttl) return null;

      final items = (entry['data'] as List)
          .map((e) => DistributoreDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      return FuelResults(items: items, fetchedAt: cachedAt);
    } catch (_) {
      await box.delete(key);
      return null;
    }
  }

  Future<void> set(String key, List<Distributore> items) async {
    final box = await _box;
    await box.put(key, {
      'cached_at': DateTime.now().toIso8601String(),
      'data': items.map(_toJson).toList(),
    });
  }

  Future<void> delete(String key) async {
    final box = await _box;
    await box.delete(key);
  }

  Map<String, dynamic> _toJson(Distributore d) => {
    'id':              d.id,
    'nome':            d.nome,
    'bandiera':        d.bandiera,
    'indirizzo':       d.indirizzo,
    'comune':          d.comune,
    'tipo_impianto':   d.isAutostradale ? 'autostradale' : 'stradale',
    'latitudine':      d.latitudine,
    'longitudine':     d.longitudine,
    'distanza_m':      d.distanzaM,
    'prezzo_self':     d.prezzoSelf,
    'prezzo_servito':  d.prezzoServito,
    'dt_aggiornamento': d.dtAggiornamento?.toIso8601String(),
  };
}
