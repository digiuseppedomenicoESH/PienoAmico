#!/usr/bin/env bash
set -euo pipefail

if [ -f scripts/.env ]; then
  export $(grep -v '^#' scripts/.env | xargs)
fi

: "${SUPABASE_URL:?Variabile SUPABASE_URL non impostata}"
: "${SUPABASE_ANON_KEY:?Variabile SUPABASE_ANON_KEY non impostata}"
: "${GOOGLE_MAPS_API_KEY:?Variabile GOOGLE_MAPS_API_KEY non impostata}"

cd app

echo "→ Build APK release..."
flutter build apk --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_API_KEY"

APK="build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "✓ APK pronto: app/$APK"
echo "  Trasferiscilo sul telefono (Drive/WhatsApp/email) e installalo."
