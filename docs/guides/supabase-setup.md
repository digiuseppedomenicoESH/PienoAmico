# Supabase Setup

## 1. Crea il progetto

1. Vai su [supabase.com](https://supabase.com) → "New project"
2. Nome: `pienoamico`
3. Password DB: generane una forte e salvala
4. Regione: **West EU (Ireland)** — la più vicina all'Italia
5. Piano: **Free**

## 2. Abilita PostGIS

Dal menu laterale: **Database → Extensions**
Cerca `postgis` → attiva.
Cerca `pg_trgm` → attiva.

## 3. Esegui le migration

Dal menu laterale: **SQL Editor → New query**

Esegui nell'ordine esatto (ogni file è idempotente grazie a `DROP IF EXISTS`):

```
001_schema.sql    → tabelle, ENUM, indici
002_functions.sql → funzione get_nearby_fuel
003_rls.sql       → Row Level Security
seed.sql          → dati di test (solo in sviluppo)
```

## 4. Verifica la funzione PostGIS

Nel SQL Editor:
```sql
SELECT * FROM get_nearby_fuel(45.4642, 9.1900, 5000, 'benzina', null, 10);
```
Se hai eseguito seed.sql deve restituire risultati per Milano.

## 5. Recupera le chiavi API

Dal menu laterale: **Project Settings → API**

| Chiave | Dove si usa | Note |
|--------|------------|------|
| `URL` | scripts/.env + app | URL del progetto |
| `anon public` | App Flutter | Lettura pubblica, sicuro da esporre |
| `service_role` | scripts/.env + GitHub Secrets | **MAI nell'app** |

## 6. Configura le chiavi in GitHub Secrets

Vai su GitHub repo → **Settings → Secrets and variables → Actions → New secret**

| Nome secret | Valore |
|------------|--------|
| `SUPABASE_URL` | `https://xxxx.supabase.co` |
| `SUPABASE_SERVICE_KEY` | `eyJ...` (service_role key) |

## Controlli Free Tier

Monitora periodicamente da **Supabase Dashboard → Reports**:
- Storage usato (limite 500 MB)
- Bandwidth mensile (limite 2 GB)

Con i dati MIMIT il progetto occuperà ~20 MB di storage e ~200-500 MB/mese di bandwidth.
