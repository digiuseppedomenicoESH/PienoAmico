class Filtri {
  final String carburante;
  final bool? isSelf;        // null = entrambi
  final int raggioMetri;
  final bool soloAutostrade;

  const Filtri({
    this.carburante    = 'benzina',
    this.isSelf,
    this.raggioMetri   = 5000,
    this.soloAutostrade = false,
  });

  Filtri copyWith({
    String? carburante,
    Object? isSelf = _sentinel,
    int? raggioMetri,
    bool? soloAutostrade,
  }) {
    return Filtri(
      carburante:     carburante     ?? this.carburante,
      isSelf:         isSelf == _sentinel ? this.isSelf : isSelf as bool?,
      raggioMetri:    raggioMetri    ?? this.raggioMetri,
      soloAutostrade: soloAutostrade ?? this.soloAutostrade,
    );
  }

  static const _sentinel = Object();

  static const carburantiDisponibili = [
    'benzina', 'gasolio', 'gpl', 'metano', 'hvo',
  ];

  static const carburantiLabel = {
    'benzina': 'Benzina',
    'gasolio': 'Gasolio',
    'gpl':     'GPL',
    'metano':  'Metano',
    'hvo':     'HVO',
  };
}
