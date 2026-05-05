class AppConstants {
  // Supabase — iniettati via --dart-define al build
  static const supabaseUrl     = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Ricerca
  static const defaultRaggioMetri = 5000;
  static const maxRaggioMetri     = 20000;
  static const maxRisultati       = 30;
  static const defaultCarburante  = 'benzina';

  // Cache
  static const cacheTtlOre   = 4;
  static const prezziStaleOre = 48;

  // AdMob — sostituire con ID reali prima della release
  static const admobBannerAdUnitId       = 'ca-app-pub-3940256099942544/6300978111';
  static const admobInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const interstitialMinIntervalMinuti = 10;
  static const interstitialMaxOgniNTap       = 4;
}
