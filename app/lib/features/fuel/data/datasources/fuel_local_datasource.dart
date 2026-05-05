import 'dart:convert';
import 'package:hive/hive.dart';

import '../../domain/entities/distributore.dart';
import '../models/distributore_dto.dart';

// Responsabile della cache locale Hive. TTL: 4 ore.
// Chiave: stringa generata da CacheKeyBuilder.
class FuelLocalDatasource {
  static const _boxName = 'fuel_cache';
  static const _ttlOre  = 4;

  Future<Box> get _box async => Hive.openBox(_boxName);

  Future<List<Distributore>?> get(String key) async {
    final box   = await _box;
    final entry = box.get(key) as Map?;
    if (entry == null) return null;

    final cachedAt = DateTime.parse(entry['cached_at'] as String);
    if (DateTime.now().difference(cachedAt).inHours >= _ttlOre) return null;

    return (entry['data'] as List)
        .map((e) => DistributoreDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> set(String key, List<Distributore> items) async {
    final box = await _box;
    await box.put(key, {
      'cached_at': DateTime.now().toIso8601String(),
      'data': items.map(_toJson).toList(),
    });
  }

  // Serializzazione minimale per Hive (no code generation richiesta)
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
