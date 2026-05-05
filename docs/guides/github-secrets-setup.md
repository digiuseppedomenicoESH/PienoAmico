# GitHub Secrets & Actions Setup

## Secrets richiesti

Vai su GitHub repo → **Settings → Secrets and variables → Actions**

| Secret | Valore | Usato da |
|--------|--------|---------|
| `SUPABASE_URL` | URL del progetto Supabase | `update-prezzi.yml` |
| `SUPABASE_SERVICE_KEY` | service_role key | `update-prezzi.yml` |

## Verifica del workflow

1. Dopo aver aggiunto i secret, vai su **Actions → Aggiornamento Prezzi Carburante**
2. Clicca **"Run workflow"** (trigger manuale) per testare senza aspettare il cron
3. Controlla i log: ogni step deve essere verde
4. Verifica su Supabase che le tabelle abbiano dati

## Log attesi da un run di successo

```json
{"event":"import_start","dry_run":false,"ts":"2026-05-05T06:30:01.000Z"}
{"event":"fetch_anagrafica_start"}
{"event":"fetch_anagrafica_done","count":19847}
{"event":"upsert_distributori","inserted":19847,"errors":0}
{"event":"fetch_prezzi_start"}
{"event":"fetch_prezzi_done","count":83241}
{"event":"upsert_prezzi","inserted":83241,"errors":0}
{"event":"import_done","ms":187432,"distributori":19847,"prezzi":83241}
```

## Alerting in caso di fallimento

GitHub Actions invia email automatica all'owner del repo se un workflow fallisce.
Assicurati che le **notifiche email GitHub siano attive** per il tuo account.

## Schedule del cron

```yaml
- cron: '30 6 * * *'   # 07:30 UTC = 08:30 CET / 09:30 CEST
- cron: '30 12 * * *'  # 13:30 UTC = 14:30 CET / 15:30 CEST
```

> Nota: GitHub Actions usa UTC. In estate (CEST, UTC+2) i run scivoleranno
> di un'ora rispetto all'orario invernale. Non è un problema — i dati MIMIT
> vengono pubblicati ad orari fissi italiani, ma si aggiornano in una finestra
> di 30-60 minuti. Il nostro script gira comunque dopo la pubblicazione.
