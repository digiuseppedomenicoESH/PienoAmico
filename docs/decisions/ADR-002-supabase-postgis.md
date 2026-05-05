# ADR-002 — Backend: Supabase + PostGIS

**Status:** Accepted
**Data:** Maggio 2026

## Contesto

Serve un backend gratuito che supporti:
- Query geografiche (trova distributori entro N km)
- Aggiornamenti batch frequenti (2x/giorno, ~100k righe)
- API REST senza server custom
- Autenticazione e autorizzazione (RLS)

Opzioni valutate: **Firebase Firestore**, **PocketBase**, **Supabase**.

## Decisione

**Supabase** con estensione **PostGIS**.

## Motivazione

| Criterio | Firebase | PocketBase | Supabase |
|----------|----------|------------|---------|
| Query geografiche | No (workaround geoHash) | Limitato | **PostGIS nativo** |
| SQL standard | No | Parziale | **Sì — PostgreSQL** |
| Free tier generoso | Sì | Self-hosted | **Sì** |
| Batch upsert | No (transazioni) | Sì | **Sì** |
| RLS granulare | Sì | Parziale | **Sì** |
| Piano gratuito con PostGIS | N/A | N/A | **Sì** |

PostGIS è l'unica soluzione che permette `ST_DWithin` su un indice GIST — rendendo la query geografica O(log n) invece di O(n). Su 20.000 distributori la differenza è 10-100ms vs 2-5 secondi.

## Conseguenze

- Positivo: query geografiche ottimizzate con indici spaziali
- Positivo: SQL standard — facile debug e ottimizzazione
- Positivo: RLS nativa per separare permessi app/script
- Negativo: progetti free si mettono in pausa dopo 7 giorni di inattività (mitigato: script giornaliero conta come attività)
- Negativo: free tier ha 500MB storage (abbondante per questo progetto)
