class Filtri {
  final String carburante;
  final int raggioMetri;

  const Filtri({
    this.carburante  = 'benzina',
    this.raggioMetri = 5000,
  });

  Filtri copyWith({
    String? carburante,
    int? raggioMetri,
  }) {
    return Filtri(
      carburante:  carburante  ?? this.carburante,
      raggioMetri: raggioMetri ?? this.raggioMetri,
    );
  }

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
