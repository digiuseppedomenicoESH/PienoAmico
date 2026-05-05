# Data Flow — MIMIT → Supabase → App

## Flusso Completo End-to-End

```
[MIMIT Server]
     │
     │  GET anagrafica_impianti_attivi.csv  (stream)
     │  GET prezzo_alle_8.csv               (stream)
     │
     ▼
[GitHub Actions — Node.js]
     │
     ├─ parseAnagrafica()
     │    ├── Salta riga 0 (data estrazione)
     │    ├── Parse con delimiter "|"
     │    ├── Filtra: lat=0 OR lon=0 → skip
     │    ├── Converte tipo_impianto → enum
     │    └── Output: Array<{id, gestore, bandiera, ..., posizione: "POINT(lon lat)"}]
     │
     ├─ batchUpsert('distributori', rows, chunkSize=500)
     │    └── ON CONFLICT (id) DO UPDATE SET ...
     │
     ├─ parsePrezzi()
     │    ├── Parse con delimiter "|"
     │    ├── Filtra: prezzo=0 OR prezzo=NULL → skip
     │    ├── Mappa descCarburante → carburante_enum
     │    ├── Converte "GG/MM/AAAA HH:MM:SS" → ISO 8601
     │    └── Output: Array<{id_impianto, carburante, is_self, prezzo, dt_comunicazione}>
     │
     └─ batchUpsert('prezzi_correnti', rows, chunkSize=1000)
          └── ON CONFLICT (id_impianto, carburante, is_self) DO UPDATE SET prezzo, dt_comunicazione

[Supabase — PostgreSQL]
     │
     │  Stato dopo upsert:
     │  - distributori: ~20.000 righe aggiornate/inserite
     │  - prezzi_correnti: ~80.000 righe con SOLO l'ultimo prezzo
     │
     ▼
[App Flutter — al tap dell'utente]
     │
     ├─ FuelRepositoryImpl.getNearbyFuel()
     │    │
     │    ├─ 1. CacheKeyBuilder.fuelResults(...) → chiave Hive
     │    ├─ 2. FuelLocalDatasource.get(key)
     │    │       ├── Cache HIT e fresca (< 4h)  → return immediato ✓
     │    │       └── Cache MISS o scaduta       → continua
     │    │
     │    ├─ 3. FuelRemoteDatasource.getNearbyFuel()
     │    │       └── supabase.rpc('get_nearby_fuel', params)
     │    │             └── PostGIS: ST_DWithin → filtra → ordina → LIMIT 30
     │    │                 Target: < 300ms
     │    │
     │    └─ 4. FuelLocalDatasource.set(key, results)  → aggiorna cache
     │
     ▼
[Riverpod — fuelResultsProvider]
     │
     └─ Notifica UI → ListView.builder renderizza lista
          Target first render con cache: < 100ms
          Target first render senza cache: < 600ms
```

## Gestione Errori nel Flusso

| Punto di fallimento | Comportamento |
|--------------------|---------------|
| MIMIT non raggiungibile | GitHub Actions fallisce, log su Actions. Dati in DB rimangono quelli del run precedente |
| Supabase non raggiungibile (script) | `batchUpsert` logga l'errore, `process.exit(1)`, Actions notifica il fallimento |
| App senza rete | Repository restituisce cache Hive scaduta se esiste, altrimenti `AppException(erroreRete)` |
| Nessun risultato nel raggio | Lista vuota → `EmptyView` |
| GPS negato | `AppException(permessoGpsNegato)` → `ErrorView` con istruzioni |

## Timing

| Evento | Orario (ora italiana) |
|--------|----------------------|
| MIMIT pubblica aggiornamento mattino | ~08:00 |
| GitHub Actions run mattino | 08:30 |
| Dati disponibili in app | ~08:35 |
| MIMIT pubblica aggiornamento pomeriggio | ~14:00 |
| GitHub Actions run pomeriggio | 14:30 |
| Dati disponibili in app | ~14:35 |
