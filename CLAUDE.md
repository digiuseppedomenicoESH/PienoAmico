# PienoAmico — Istruzioni per Claude

App Android per monitoraggio prezzi carburante in Italia.
Documento di progetto completo: `PROGETTO_BIBBIA.md` — leggilo sempre prima di fare scelte architetturali.

---

## Stack

| Layer | Tecnologia |
|-------|-----------|
| App mobile | Flutter (Dart), solo Android, minSdkVersion 23 |
| Backend / DB | Supabase (PostgreSQL 15 + PostGIS) |
| Automazione dati | GitHub Actions (Node.js 20) |
| Sorgente dati | CSV open data MIMIT (gratuiti) |
| Mappe | flutter_map + OpenStreetMap |
| Pubblicità | Google AdMob |

---

## Struttura Cartelle

```
pienoamico/
├── .github/workflows/          # GitHub Actions CI/CD
├── scripts/                    # Pipeline Node.js importazione dati
│   ├── parsers/                # Parser CSV anagrafica e prezzi
│   └── package.json
├── supabase/migrations/        # DDL SQL — schema, funzioni, RLS
├── app/                        # Progetto Flutter
│   └── lib/
│       ├── core/               # Costanti, tema, eccezioni
│       ├── data/               # Servizi: Supabase, GPS, Cache
│       ├── models/             # Model classes + fromJson
│       ├── screens/            # UI screens
│       └── widgets/            # Widget riutilizzabili
└── PROGETTO_BIBBIA.md          # Documento di riferimento progetto
```

---

## Regole Critiche — Non Derogabili

### Sicurezza
- La `SUPABASE_SERVICE_KEY` NON deve mai comparire nell'app Flutter. Solo in GitHub Secrets.
- L'app Flutter usa esclusivamente la `SUPABASE_ANON_KEY` (read-only grazie a RLS).
- Le policy RLS su Supabase permettono solo `SELECT` all'utente `anon`.

### Database
- **Mai** fare upsert riga per riga nei CSV — sempre batch (chunk da 500 per anagrafica, 1000 per prezzi).
- La tabella `prezzi_correnti` contiene **solo l'ultimo prezzo** per combinazione `(id_impianto, carburante, is_self)`. Non è una tabella storica.
- Tutti gli indici sono già definiti in `supabase/migrations/001_schema.sql` — non aggiungerne senza analisi `EXPLAIN ANALYZE`.
- Il tipo geografico è `GEOGRAPHY(POINT, 4326)`, non `GEOMETRY`. Questo è intenzionale per avere distanze in metri.

### Performance
- Query Supabase target: **< 300ms**
- First render app target: **< 500ms**
- Usare sempre `ListView.builder` (mai `ListView` con figli statici) per liste distributori.
- Cache locale Hive con TTL 4 ore — non fare fetch se cache valida.

### Dati MIMIT
- Separatore CSV: **pipe `|`** (cambiato il 10/02/2026, non più virgola).
- Encoding: UTF-8.
- La prima riga del file anagrafica è una riga di intestazione con la data (`Estrazione del AAAA-MM-GG`), non l'header delle colonne — skipparla.
- Formato data in `dtComu`: `GG/MM/AAAA HH:MM:SS` → convertire in ISO 8601 prima di inserire in DB.
- Filtrare prezzi con `prezzo = 0` o `NULL` (dati sporchi frequenti).
- Skipare distributori con `Latitudine = 0` o `Longitudine = 0`.

---

## Convenzioni Codice

### Dart / Flutter
- Nomi file: `snake_case.dart`
- Nomi classi: `PascalCase`
- Nomi variabili/metodi: `camelCase`
- Nessun commento esplicativo ovvio — solo commenti per logiche non intuitive.
- Usare `const` dove possibile per widget statici.
- Gestione errori: usare il tipo `AppException` definito in `core/exceptions.dart`.
- Nessuna logica di business nei widget — tutto in `data/` o nei `model`.

### Node.js (scripts)
- Moduli ES (`"type": "module"` in package.json).
- `async/await` ovunque, nessuna callback.
- Logging strutturato: `console.log(JSON.stringify({ event, count, ms }))`.
- Le funzioni di parsing devono essere pure (input → output, no side effects).

### SQL
- Nomi tabelle e colonne: `snake_case`.
- Ogni migration in un file separato con prefisso numerico (`001_`, `002_`, ecc.).
- Ogni `CREATE` preceduto da `DROP ... IF EXISTS` per idempotenza.
- Aggiungere `COMMENT ON` per colonne non ovvie.

---

## Comandi Utili

```bash
# Avviare app Flutter in modalità debug
cd app && flutter run

# Build APK di test
cd app && flutter build apk --debug

# Build AAB per Play Store
cd app && flutter build appbundle --release

# Eseguire script import dati in locale (richiede .env)
cd scripts && node import.js

# Applicare migrations Supabase (richiede Supabase CLI)
supabase db push

# Verificare query geografica direttamente su DB
# (usa Supabase SQL editor con la funzione get_nearby_fuel)
```

---

## URL e Costanti Importanti

```
CSV Anagrafica : https://www.mimit.gov.it/images/exportCSV/anagrafica_impianti_attivi.csv
CSV Prezzi     : https://www.mimit.gov.it/images/exportCSV/prezzo_alle_8.csv
```

---

## Ordine di Sviluppo Consigliato

1. `supabase/migrations/` — schema SQL completo
2. `scripts/` — pipeline Node.js + test import reale
3. `.github/workflows/` — automazione GitHub Actions
4. `app/` — Flutter, partendo da `data/supabase_service.dart`

Non iniziare il Flutter prima che il backend funzioni e i dati siano verificati in DB.

---

## File di Riferimento

- `PROGETTO_BIBBIA.md` — visione, logica di business, schema DB completo, roadmap
- `supabase/migrations/001_schema.sql` — DDL tabelle e indici
- `supabase/migrations/002_functions.sql` — funzione PostGIS `get_nearby_fuel`
- `supabase/migrations/003_rls.sql` — Row Level Security
- `scripts/package.json` — dipendenze Node.js script
- `app/pubspec.yaml` — dipendenze Flutter
