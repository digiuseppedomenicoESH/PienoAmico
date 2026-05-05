enum AppErrorType {
  gpsDisabilitato,
  permessoGpsNegato,
  nessunRisultato,
  erroreRete,
  erroreServer,
  cacheScadutaOffline,
}

class AppException implements Exception {
  final AppErrorType type;
  final String? dettaglio;

  const AppException(this.type, {this.dettaglio});

  @override
  String toString() => 'AppException(${type.name}: $dettaglio)';
}
