import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/app_constants.dart';

// Gestione centralizzata AdMob: banner e interstitial.
// L'interstitial viene precaricato in background e mostrato max 1 ogni 4 tap "Naviga".
class AdmobService {
  InterstitialAd? _interstitialAd;
  int  _tapCountSinceLastAd    = 0;
  DateTime? _lastInterstitialAt;

  Future<void> initialize() => MobileAds.instance.initialize();

  Future<void> loadInterstitial() async {
    await InterstitialAd.load(
      adUnitId: AppConstants.admobInterstitialAdUnitId,
      request:  const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded:       (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_)  => _interstitialAd = null,
      ),
    );
  }

  // Chiamare ogni volta che l'utente preme "Naviga".
  // Restituisce true se l'interstitial è stato mostrato.
  bool maybeShowInterstitial() {
    _tapCountSinceLastAd++;

    final minIntervalPassato = _lastInterstitialAt == null ||
        DateTime.now().difference(_lastInterstitialAt!).inMinutes >=
            AppConstants.interstitialMinIntervalMinuti;

    if (_tapCountSinceLastAd >= AppConstants.interstitialMaxOgniNTap &&
        minIntervalPassato &&
        _interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd       = null;
      _tapCountSinceLastAd  = 0;
      _lastInterstitialAt   = DateTime.now();
      loadInterstitial();   // precarica il prossimo
      return true;
    }

    return false;
  }

  BannerAd buildBannerAd(AdSize size) => BannerAd(
    adUnitId: AppConstants.admobBannerAdUnitId,
    size:     size,
    request:  const AdRequest(),
    listener: BannerAdListener(
      onAdFailedToLoad: (ad, _) => ad.dispose(),
    ),
  );
}
