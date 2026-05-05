extension PrezzoFormat on double {
  // "1.659" → "1,659 €/L"
  String get asPrezzo => '${toStringAsFixed(3).replaceAll('.', ',')} €/L';

  // "1843" → "1,8 km" oppure "843" → "843 m"
  String get asDistanza {
    if (this >= 1000) return '${(this / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
    return '${toInt()} m';
  }
}
