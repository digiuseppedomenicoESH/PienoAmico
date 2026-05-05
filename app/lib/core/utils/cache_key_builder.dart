// Genera chiavi deterministiche per la cache Hive.
// La chiave identifica univocamente un insieme di risultati in base ai parametri della query.

class CacheKeyBuilder {
  static String fuelResults({
    required double lat,
    required double lon,
    required int raggioMetri,
    required String carburante,
    bool? isSelf,
  }) {
    final latR  = lat.toStringAsFixed(3);
    final lonR  = lon.toStringAsFixed(3);
    final self  = isSelf == null ? 'all' : (isSelf ? 'self' : 'servito');
    return 'fuel_${latR}_${lonR}_r${raggioMetri}_${carburante}_$self';
  }
}
