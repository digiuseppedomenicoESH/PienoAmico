# PienoAmico — Documentazione

Indice di tutta la documentazione tecnica e progettuale.

---

## Architettura
| File | Contenuto |
|------|-----------|
| [system-overview.md](architecture/system-overview.md) | Visione d'insieme del sistema, diagrammi componenti |
| [database-schema.md](architecture/database-schema.md) | Schema DB, indici, strategia performance |
| [data-flow.md](architecture/data-flow.md) | Flusso dati MIMIT → Supabase → App |
| [flutter-clean-architecture.md](architecture/flutter-clean-architecture.md) | Architettura Flutter: layer, responsabilità, regole |

## API
| File | Contenuto |
|------|-----------|
| [supabase-functions.md](api/supabase-functions.md) | Documentazione RPC `get_nearby_fuel` |

## Guide Operative
| File | Contenuto |
|------|-----------|
| [local-setup.md](guides/local-setup.md) | Come configurare l'ambiente locale |
| [supabase-setup.md](guides/supabase-setup.md) | Setup Supabase: progetto, estensioni, migrations |
| [github-secrets-setup.md](guides/github-secrets-setup.md) | Configurazione GitHub Secrets per CI/CD |
| [play-store-release.md](guides/play-store-release.md) | Processo di build e release su Google Play Store |

## Architecture Decision Records (ADR)
Documenti che spiegano il **perché** delle scelte architetturali principali.

| ADR | Decisione |
|-----|-----------|
| [ADR-001](decisions/ADR-001-state-management.md) | Riverpod come state management |
| [ADR-002](decisions/ADR-002-supabase-postgis.md) | Supabase + PostGIS come backend |
| [ADR-003](decisions/ADR-003-no-price-history.md) | Nessuna tabella storica prezzi |
| [ADR-004](decisions/ADR-004-mimit-csv.md) | CSV MIMIT come sorgente dati primaria |
