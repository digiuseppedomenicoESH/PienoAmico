class PrezzoRecord {
  final String carburante;
  final double? prezzoSelf;
  final double? prezzoServito;
  final DateTime? dtUltima;

  const PrezzoRecord({
    required this.carburante,
    this.prezzoSelf,
    this.prezzoServito,
    this.dtUltima,
  });

  double? get prezzoBest => prezzoSelf ?? prezzoServito;
}
