# PienoAmico

App Android per trovare il carburante più economico vicino a te, basata su dati open MIMIT aggiornati automaticamente ogni giorno.

---

## Stack

| Layer | Tecnologia |
|---|---|
| App mobile | Flutter (Dart) — solo Android, minSdk 23 |
| Backend / DB | Supabase (PostgreSQL 15 + PostGIS) |
| Automazione dati | GitHub Actions (Node.js 22) |
| Sorgente dati | CSV open data MIMIT (gratuiti) |
| Pubblicità | Google AdMob |

---

## Prerequisiti

| Tool | Versione minima | Note |
|---|---|---|
| Flutter | 3.19+ | `flutter --version` |
| Dart | 3.3+ | incluso con Flutter |
| Node.js | 22+ | per gli script di importazione |
| Android Studio | Hedgehog+ | per l'emulatore Android |
| Supabase CLI | latest | per le migrations |

---

## Setup iniziale

### 1. Clona il repository

```bash
git clone https://github.com/digiuseppedomenicoESH/PienoAmico.git
cd PienoAmico
```

### 2. Configura Supabase

1. Crea un progetto su [supabase.com](https://supabase.com)
2. Vai su **Settings → API** e copia:
   - **Project URL** (es. `https://xxxx.supabase.co`)
   - **anon public** key
   - **service_role** key (solo per GitHub Secrets — non va mai nel client)
3. Applica le migrations al database:

```bash
# Installa Supabase CLI se non ce l'hai
brew install supabase/tap/supabase

# Applica schema, funzioni e RLS
supabase db push
```

Le migrations si trovano in `supabase/migrations/`:
- `001_schema.sql` — tabelle `distributori` e `prezzi_correnti`
- `002_functions.sql` — funzione PostGIS `get_nearby_fuel`
- `003_rls.sql` — Row Level Security (anon = solo SELECT)

### 3. Configura i GitHub Secrets

Nel repository GitHub → **Settings → Secrets and variables → Actions**, aggiungi:

| Secret | Valore |
|---|---|
| `SUPABASE_URL` | URL del progetto Supabase |
| `SUPABASE_SERVICE_KEY` | service_role key |

Il workflow `.github/workflows/update-prezzi.yml` gira automaticamente alle 07:30 e 13:30 UTC ogni giorno.

### 4. Importa i dati per la prima volta (opzionale)

Per popolare il database subito senza aspettare il workflow:

```bash
cd scripts
npm install

# Crea il file .env con le credenziali
echo "SUPABASE_URL=https://xxxx.supabase.co" > .env
echo "SUPABASE_SERVICE_KEY=eyJ..." >> .env

node import.js
```

---

## Avviare l'app Flutter

### Con emulatore Android

1. Apri **Android Studio → Device Manager → Create Device**
2. Scegli *Pixel 7* — sistema *API 34* — avvialo con ▶
3. Imposta una posizione GPS nell'emulatore:
   - Clicca `···` nella barra laterale → **Location**
   - Cerca "Milano" (o un'altra città) e clicca **Set Location**

```bash
cd app

flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

> **Importante:** usa sempre la chiave **anon** (non la service_role) nel client Flutter.

### Con dispositivo fisico Android

1. Abilita le **Opzioni sviluppatore** sul telefono (tocca "Numero build" 7 volte in *Impostazioni → Info*)
2. Attiva **Debug USB**
3. Collega il telefono via USB e autorizza il debug
4. Verifica che Flutter lo rilevi: `flutter devices`
5. Avvia con lo stesso comando `flutter run` sopra

### Comandi utili durante lo sviluppo

| Comando | Descrizione |
|---|---|
| `r` nel terminale | Hot reload |
| `R` nel terminale | Hot restart |
| `q` nel terminale | Chiudi l'app |
| `flutter analyze` | Analisi statica |
| `flutter build apk --debug` | Build APK di test |
| `flutter build appbundle --release` | Build AAB per Play Store |

---

## Struttura del progetto

```
PienoAmico/
├── .github/workflows/          # GitHub Actions — import dati giornaliero
├── scripts/                    # Pipeline Node.js importazione CSV MIMIT
│   ├── parsers/
│   │   ├── anagrafica.js       # Parser CSV distributori
│   │   └── prezzi.js           # Parser CSV prezzi
│   └── import.js               # Entry point importazione
├── supabase/migrations/        # DDL SQL — schema, funzioni PostGIS, RLS
├── app/                        # Progetto Flutter
│   └── lib/
│       ├── core/               # Tema, router, costanti, eccezioni
│       ├── features/
│       │   ├── fuel/           # Feature principale (lista + dettaglio)
│       │   ├── location/       # Servizio GPS
│       │   └── settings/       # Impostazioni
│       └── shared/             # Widget condivisi, AdMob service
└── PROGETTO_BIBBIA.md          # Documento di riferimento completo
```

---

## Variabili d'ambiente

| Variabile | Dove si usa | Come si passa |
|---|---|---|
| `SUPABASE_URL` | App Flutter | `--dart-define` al build/run |
| `SUPABASE_ANON_KEY` | App Flutter | `--dart-define` al build/run |
| `SUPABASE_URL` | Script Node.js | file `.env` in `scripts/` |
| `SUPABASE_SERVICE_KEY` | Script Node.js / CI | file `.env` o GitHub Secret |

> La `SERVICE_KEY` non deve mai essere inclusa nell'app Flutter.

---

## Dati MIMIT

I prezzi vengono importati automaticamente da:
- **Anagrafica impianti:** `https://www.mimit.gov.it/images/exportCSV/anagrafica_impianti_attivi.csv`
- **Prezzi alle 8:** `https://www.mimit.gov.it/images/exportCSV/prezzo_alle_8.csv`

Separatore: `|` (pipe). Aggiornati ogni mattina dal Ministero.
