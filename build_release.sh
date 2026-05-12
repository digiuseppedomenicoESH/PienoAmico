#!/usr/bin/env bash
set -euo pipefail

# Carica le variabili da .env se presente
if [ -f scripts/.env ]; then
  set -a
  source scripts/.env
  set +a
fi

: "${SUPABASE_URL:?Variabile SUPABASE_URL non impostata}"
: "${SUPABASE_ANON_KEY:?Variabile SUPABASE_ANON_KEY non impostata}"
: "${GOOGLE_MAPS_API_KEY:?Variabile GOOGLE_MAPS_API_KEY non impostata}"

cd app

echo "→ Pulizia..."
flutter clean

echo "→ Dipendenze..."
flutter pub get

echo "→ Build AAB release..."
flutter build appbundle --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_API_KEY"

AAB="build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "✓ Build completata: app/$AAB"
echo "  Carica questo file su Google Play Console."
