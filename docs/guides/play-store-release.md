# Release Google Play Store

## Prerequisiti

- Account Google Play Console (€25 una tantum)
- Keystore firmato (vedi sotto)
- Privacy Policy pubblicata online (obbligatoria per AdMob)
- ID AdMob reali (non di test)

## 1. Sostituisci gli ID AdMob di test

Prima della release, aggiorna `app/lib/core/constants/app_constants.dart`:
```dart
// Da (test):
static const admobBannerAdUnitId       = 'ca-app-pub-3940256099942544/6300978111';
static const admobInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

// A (produzione — IDs dal tuo account AdMob):
static const admobBannerAdUnitId       = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
static const admobInterstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
```

Aggiorna anche `AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
```

## 2. Crea il Keystore (una volta sola)

```bash
keytool -genkey -v \
  -keystore app/android/app/pienoamico-release.jks \
  -alias pienoamico \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

> **CRITICO:** Salva il file `.jks` e le password in un posto sicuro.
> Se perdi il keystore non puoi più aggiornare l'app sul Play Store.
> Il file è nel `.gitignore` — non committarlo mai.

## 3. Configura key.properties

Crea `app/android/key.properties` (nel `.gitignore`):
```
storePassword=<password-keystore>
keyPassword=<password-chiave>
keyAlias=pienoamico
storeFile=../app/pienoamico-release.jks
```

## 4. Build AAB (Android App Bundle)

```bash
cd app
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Il file `.aab` si trova in `app/build/app/outputs/bundle/release/app-release.aab`

## 5. Pubblica su Play Console

1. Crea una nuova app su [play.google.com/console](https://play.google.com/console)
2. **Configurazione app:** categoria Utilità, privacy policy URL
3. **Produzione → Crea release → Carica AAB**
4. Compila: descrizione (IT/EN), screenshot (almeno 2), icona 512x512
5. **Revisione:** Google impiega 1-3 giorni per la prima release

## Checklist pre-release

- [ ] ID AdMob reali (non di test)
- [ ] Privacy Policy online (può essere una GitHub Page)
- [ ] `minSdkVersion 23` in AndroidManifest
- [ ] Icona app (512x512 PNG, nessun canale alpha)
- [ ] Screenshot (almeno 2, formato telefono)
- [ ] Descrizione breve (≤80 caratteri) e lunga
- [ ] Testato su dispositivo fisico reale
- [ ] Test scenario offline
- [ ] Test con GPS disabilitato
- [ ] `flutter analyze` senza errori
- [ ] `flutter test` tutti i test passano
