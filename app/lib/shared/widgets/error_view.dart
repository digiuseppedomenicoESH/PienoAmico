import 'package:flutter/material.dart';
import '../../core/errors/exceptions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ErrorView extends StatelessWidget {
  final AppException exception;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.exception, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.prezzoHighBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.prezzoHigh.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 34,
                color: AppColors.prezzoHigh,
              ),
            ),
            const SizedBox(height: 20),
            Text(_title, style: AppTextStyles.statoTitolo),
            const SizedBox(height: 8),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: AppTextStyles.statoMessaggio,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Riprova'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String get _title => switch (exception.type) {
        AppErrorType.gpsDisabilitato     => 'GPS disabilitato',
        AppErrorType.permessoGpsNegato   => 'Permesso negato',
        AppErrorType.nessunRisultato     => 'Nessun risultato',
        AppErrorType.erroreRete          => 'Nessuna connessione',
        AppErrorType.erroreServer        => 'Errore del server',
        AppErrorType.cacheScadutaOffline => 'Dati non aggiornati',
      };

  String get _message => switch (exception.type) {
        AppErrorType.gpsDisabilitato     => 'Attiva il GPS dalle impostazioni del dispositivo.',
        AppErrorType.permessoGpsNegato   => 'Il permesso di posizione è necessario per trovare i distributori vicini.',
        AppErrorType.nessunRisultato     => 'Nessun distributore trovato nel raggio selezionato.',
        AppErrorType.erroreRete          => 'Controlla la connessione e riprova.',
        AppErrorType.erroreServer        => 'Si è verificato un problema con il server. Riprova tra qualche minuto.',
        AppErrorType.cacheScadutaOffline => 'Connettiti a internet per aggiornare i dati.',
      };
}
