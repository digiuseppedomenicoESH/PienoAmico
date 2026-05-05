# Setup Ambiente Locale

## Prerequisiti

| Tool | Versione minima | Verifica |
|------|----------------|---------|
| Flutter SDK | 3.22+ | `flutter --version` |
| Dart | 3.3+ | incluso in Flutter |
| Node.js | 20+ | `node --version` |
| npm | 10+ | `npm --version` |

## 1. Clona e installa dipendenze

```bash
git clone <repo-url> pienoamico
cd pienoamico

# Dipendenze Node.js (script import)
cd scripts && npm install && cd ..

# Dipendenze Flutter
cd app && flutter pub get && cd ..
```

## 2. Configura variabili d'ambiente (scripts)

```bash
cp scripts/.env.example scripts/.env
# Apri scripts/.env e inserisci SUPABASE_URL e SUPABASE_SERVICE_KEY
```

## 3. Esegui le migration Supabase

Vai su [Supabase Dashboard](https://supabase.com) → SQL Editor ed esegui nell'ordine:
1. `supabase/migrations/001_schema.sql`
2. `supabase/migrations/002_functions.sql`
3. `supabase/migrations/003_rls.sql`
4. `supabase/seed.sql` (opzionale — dati di test)

Vedi [supabase-setup.md](supabase-setup.md) per la guida completa.

## 4. Testa lo script import in dry-run

```bash
cd scripts
DRY_RUN=true node import.js
# Deve stampare log JSON con event: "import_done" senza scrivere su DB
```

## 5. Esegui import reale (prima volta)

```bash
cd scripts
node import.js
# Attendi ~2-3 minuti — scarica e importa ~20.000 distributori e ~80.000 prezzi
```

## 6. Avvia l'app Flutter

```bash
cd app
# Con variabili Supabase iniettate via dart-define
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

> Consiglio: crea uno script `app/run_dev.sh` con i dart-define precompilati (non committarlo).

## Comandi utili

```bash
# Linting Flutter
cd app && flutter analyze

# Test Flutter
cd app && flutter test

# Build APK debug
cd app && flutter build apk --debug

# Import script in dry-run
cd scripts && DRY_RUN=true node import.js
```
