class CacheKeyBuilder {
  static String fuelResults({
    required double lat,
    required double lon,
    required int raggioMetri,
    required String carburante,
  }) {
    final latR = lat.toStringAsFixed(3);
    final lonR = lon.toStringAsFixed(3);
    return 'fuel_${latR}_${lonR}_r${raggioMetri}_$carburante';
  }
}
