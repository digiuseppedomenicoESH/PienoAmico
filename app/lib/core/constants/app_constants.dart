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

  static const admobBannerAdUnitId       = 'ca-app-pub-9139935695451710/8604978437';
  static const admobInterstitialAdUnitId = 'ca-app-pub-9139935695451710/6424253794';
  static const interstitialMinIntervalMinuti = 10;
  static const interstitialMaxOgniNTap       = 4;
}
