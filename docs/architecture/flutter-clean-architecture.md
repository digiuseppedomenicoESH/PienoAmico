# Flutter Clean Architecture — PienoAmico

## Struttura a Layer

```
┌──────────────────────────────────────────┐
│           PRESENTATION LAYER             │
│  providers/ · screens/ · widgets/        │
│  Riverpod FutureProvider, Notifier       │
│  Dipende da: Domain                      │
├──────────────────────────────────────────┤
│             DOMAIN LAYER                 │
│  entities/ · repositories/ · usecases/  │
│  Puro Dart — zero import Flutter/Supa   │
│  Dipende da: nessuno                     │
├──────────────────────────────────────────┤
│              DATA LAYER                  │
│  datasources/ · models/ · repositories/ │
│  Implementa interfacce domain            │
│  Dipende da: Domain, Supabase, Hive      │
└──────────────────────────────────────────┘
```

**Regola d'oro:** le dipendenze puntano sempre verso l'interno.
- Presentation conosce Domain, non conosce Data
- Domain non conosce nessuno dei layer esterni
- Data conosce Domain (implementa le sue interfacce)

## Responsabilità per File

### Domain Layer — logica pura

| File | Responsabilità |
|------|---------------|
| `entities/distributore.dart` | Struttura dati del distributore. Proprietà calcolate (`prezzoBest`, `isPrezzoFresco`) |
| `entities/filtri.dart` | Stato filtri utente. `copyWith` immutabile |
| `repositories/fuel_repository.dart` | **Interfaccia astratta**. Il presentation layer dipende da questa, non dall'implementazione |
| `usecases/get_nearby_fuel_usecase.dart` | Unico entry point. Aggiunge validazione dominio (es. raggio max) |

### Data Layer — implementazioni concrete

| File | Responsabilità |
|------|---------------|
| `models/distributore_dto.dart` | **Solo** deserializzazione JSON → Entity. Nessuna logica |
| `datasources/fuel_remote_datasource.dart` | **Solo** chiamata Supabase RPC. Nessuna logica cache |
| `datasources/fuel_local_datasource.dart` | **Solo** lettura/scrittura Hive. Gestisce TTL |
| `repositories/fuel_repository_impl.dart` | Orchestra cache-first: local → remote → fallback |

### Presentation Layer — UI e stato

| File | Responsabilità |
|------|---------------|
| `providers/fuel_provider.dart` | Wiring dipendenze + `FutureProvider` che reagisce a posizione e filtri |
| `providers/filters_provider.dart` | `NotifierProvider` — stato mutabile dei filtri utente |
| `screens/home_screen.dart` | Schermata principale. Legge `fuelResultsProvider`, gestisce stati |
| `screens/detail_screen.dart` | Dettaglio distributore. Mostra tutti i prezzi + naviga |
| `widgets/fuel_card.dart` | Card lista. Riceve `Distributore`, non tocca provider |
| `widgets/price_badge.dart` | Badge colorato prezzo (verde/giallo/rosso) |

## Flusso di un'interazione tipica

```
Utente cambia carburante da "benzina" a "gasolio"
    │
    ▼
FiltersBottomSheet → ref.read(filtriProvider.notifier).setCarburante('gasolio')
    │
    ▼
filtriProvider emette nuovo stato Filtri(carburante: 'gasolio')
    │
    ▼
fuelResultsProvider si invalida (dipende da filtriProvider)
    │
    ▼
FuelRepositoryImpl.getNearbyFuel(carburante: 'gasolio')
    ├── CacheKey diversa → cache miss
    └── FuelRemoteDatasource.getNearbyFuel() → Supabase RPC
    │
    ▼
HomeScreen rebuilda con AsyncValue.loading → poi .data
    └── ListView.builder mostra nuova lista ordinata per prezzo gasolio
```

## Regole di Codice

1. **Widget ricevono Entity, non leggono provider** — `FuelCard` riceve `Distributore`, non usa `ref`
2. **Un provider = una responsabilità** — non mescolare posizione e filtri in un unico provider
3. **Nessun `BuildContext` fuori dai widget** — la logica non tocca il context
4. **Nessun `setState` nelle screen** — tutto passa per Riverpod
5. **`const` ovunque possibile** — riduce rebuild inutili
