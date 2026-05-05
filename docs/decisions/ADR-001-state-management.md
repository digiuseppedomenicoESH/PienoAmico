# ADR-001 — State Management: Riverpod

**Status:** Accepted
**Data:** Maggio 2026

## Contesto

L'app ha bisogno di gestire stato asincrono complesso:
- Posizione GPS (async, può fallire)
- Risultati Supabase (async, dipende da GPS + filtri)
- Filtri utente (sincrono, mutabile)
- Cache locale (async)

Si valutavano tre opzioni: **Provider**, **Bloc**, **Riverpod**.

## Decisione

**Riverpod** con `FutureProvider`, `NotifierProvider` e `ref.watch`.

## Motivazione

| Criterio | Provider | Bloc | Riverpod |
|----------|----------|------|----------|
| Boilerplate | Basso | Alto | Basso |
| Composizione provider | Manuale | Manuale | Nativa (`ref.watch`) |
| Stato asincrono | Limitato | Verboso | Nativo (`AsyncValue`) |
| Testabilità | Media | Alta | Alta |
| Maturità (2026) | Stabile | Stabile | Stabile |
| Curva apprendimento | Bassa | Media | Media |

Il punto chiave: `fuelResultsProvider` deve **ricalcolarsi automaticamente** quando cambia la posizione GPS o i filtri. Con Riverpod questo è una riga:

```dart
final fuelResultsProvider = FutureProvider((ref) async {
  final position = await ref.watch(locationProvider.future); // reattivo
  final filtri   = ref.watch(filtriProvider);                // reattivo
  return useCase.call(lat: position.latitude, ...);
});
```

Con Provider o Bloc richiederebbe listener manuali e gestione di race condition.

## Conseguenze

- Positivo: zero boilerplate per stati derivati e composizione
- Positivo: `AsyncValue` gestisce loading/error/data nativamente
- Negativo: `ProviderScope` richiede un widget wrapper al root dell'app
- Negativo: curva di apprendimento iniziale per chi viene da Provider classico
