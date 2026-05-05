import 'package:flutter/material.dart';
import '../../core/errors/exceptions.dart';

// Widget generico per stati di errore. Usato in tutte le screen.
class ErrorView extends StatelessWidget {
  final AppException exception;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.exception, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Riprova')),
            ],
          ],
        ),
      ),
    );
  }

  String get _message => switch (exception.type) {
    AppErrorType.gpsDisabilitato     => 'GPS disabilitato.\nAttivalo dalle impostazioni.',
    AppErrorType.permessoGpsNegato   => 'Permesso posizione negato.\nNecessario per trovare distributori vicini.',
    AppErrorType.nessunRisultato     => 'Nessun distributore trovato nel raggio selezionato.',
    AppErrorType.erroreRete          => 'Nessuna connessione.\nControlla la rete e riprova.',
    AppErrorType.erroreServer        => 'Errore del server. Riprova tra qualche minuto.',
    AppErrorType.cacheScadutaOffline => 'Dati non aggiornati. Connettiti a internet.',
  };
}
