class Filtri {
  final String carburante;
  final bool? isSelf;        // null = entrambi
  final int raggioMetri;

  const Filtri({
    this.carburante  = 'benzina',
    this.isSelf,
    this.raggioMetri = 5000,
  });

  Filtri copyWith({
    String? carburante,
    Object? isSelf = _sentinel,
    int? raggioMetri,
  }) {
    return Filtri(
      carburante:  carburante  ?? this.carburante,
      isSelf:      isSelf == _sentinel ? this.isSelf : isSelf as bool?,
      raggioMetri: raggioMetri ?? this.raggioMetri,
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
