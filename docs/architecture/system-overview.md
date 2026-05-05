# System Overview — PienoAmico

## Componenti del Sistema

```
┌──────────────────────────────────────────────────────────────────────┐
│                         SORGENTE DATI                                │
│                                                                      │
│   MIMIT — Ministero delle Imprese e del Made in Italy                │
│   ├── anagrafica_impianti_attivi.csv  (~1.5 MB, ~20.000 righe)       │
│   └── prezzo_alle_8.csv              (~3-5 MB, ~100.000+ righe)      │
│   Aggiornamento: 2x/giorno (08:00 e 14:00)                           │
│   Formato: CSV con separatore PIPE |, encoding UTF-8                 │
└───────────────────────────────┬──────────────────────────────────────┘
                                │ HTTPS download 2x/giorno
                                ▼
┌──────────────────────────────────────────────────────────────────────┐
│                         GITHUB ACTIONS                               │
│                                                                      │
│   Trigger: cron 07:30 UTC e 13:30 UTC                                │
│   Runtime: ubuntu-latest, Node.js 20, timeout 15min                  │
│                                                                      │
│   Flusso:                                                            │
│   1. Download CSV anagrafica (stream, no buffer)                     │
│   2. Parse + validazione (filtra lat=0, prezzo=0)                    │
│   3. Batch upsert distributori → Supabase [chunk 500]                │
│   4. Download CSV prezzi (stream)                                    │
│   5. Parse + normalizza enum carburante + converti date              │
│   6. Batch upsert prezzi → Supabase [chunk 1000]                     │
│   7. Log JSON strutturato (event, count, ms)                         │
└───────────────────────────────┬──────────────────────────────────────┘
                                │ REST API (service_role key)
                                ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    SUPABASE (Free Tier)                              │
│                                                                      │
│   PostgreSQL 15 + PostGIS                                            │
│                                                                      │
│   tabella: distributori                                              │
│   ├── ~20.000 righe (anagrafica impianti)                            │
│   ├── indice GIST su posizione GEOGRAPHY(POINT,4326)                 │
│   └── indice su provincia, tipo_impianto                             │
│                                                                      │
│   tabella: prezzi_correnti                                           │
│   ├── ~60.000-100.000 righe (ultima riga per impianto+carb+modalità) │
│   ├── indici parziali su is_self=true e is_self=false                │
│   └── indice su (carburante, prezzo ASC)                             │
│                                                                      │
│   function: get_nearby_fuel(lat, lon, raggio, carb, is_self, limit)  │
│   └── target latenza: < 300ms                                        │
│                                                                      │
│   RLS: anon → solo SELECT | service_role → full access               │
└───────────────────────────────┬──────────────────────────────────────┘
                                │ Supabase SDK (anon key)
                                ▼
┌──────────────────────────────────────────────────────────────────────┐
│                     APP FLUTTER (Android)                            │
│                                                                      │
│   minSdkVersion: 23 (Android 6.0)                                   │
│                                                                      │
│   Strati (Clean Architecture):                                       │
│   ├── domain/      → entities, repository interface, use case        │
│   ├── data/        → Supabase datasource, Hive cache, repository impl│
│   └── presentation → Riverpod providers, screens, widgets           │
│                                                                      │
│   Cache locale: Hive, TTL 4 ore, fallback su cache scaduta offline   │
│   Mappe: flutter_map + OpenStreetMap tiles (gratuito)                │
│   Pubblicità: Google AdMob (banner + interstitial)                   │
│   Navigazione: go_router                                             │
│   Target first render: < 500ms (con cache)                           │
└──────────────────────────────────────────────────────────────────────┘
```

## Principi di Progettazione

| Principio | Come è applicato |
|-----------|-----------------|
| **Costo zero** | Free tier Supabase + GitHub Actions + OSM. Solo €25 per Play Console |
| **Dati ufficiali** | Solo CSV MIMIT (fonte governativa) — nessun scraping |
| **Performance first** | Indici GIST + parziali, cache locale, batch upsert, LIMIT integrato |
| **Sicurezza** | `service_role` mai nell'app. RLS enforced. Nessun dato utente raccolto |
| **Resilienza** | Fallback su cache scaduta in caso di rete assente |
| **Scalabilità** | L'architettura regge fino a ~100k utenti/mese sul free tier |

## Limiti del Free Tier Supabase

| Risorsa | Limite | Stima utilizzo |
|---------|--------|----------------|
| Storage DB | 500 MB | ~50-80 MB (no storico) |
| Bandwidth | 2 GB/mese | ~500 MB/mese (con gzip) |
| Pausing inattività | 7 giorni | Non applicabile (script giornaliero) |
| Connessioni simultanee | 60 | Abbondante per v1 |
