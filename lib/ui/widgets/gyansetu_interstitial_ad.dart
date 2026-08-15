import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GyansetuInterstitialAd {
  static InterstitialAd? _interstitialAd;
  static bool _isLoaded = false;

  // 🎯 GYANSETU INTERSTITIAL AD ID
  static const String adUnitId = 'ca-app-pub-2076369951420983/4386314591';

  // App start hote hi ad load karne ke liye
  static void loadAd() {
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoaded = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _isLoaded = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  // Jaha ad dikhani ho, waha ye function call hoga
  static void showAd({required VoidCallback onComplete}) {
    if (_isLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isLoaded = false;
          loadAd(); // Agli baar ke liye nayi ad load kar lo
          onComplete(); // Ad katne ke baad asli function chalne do
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isLoaded = false;
          loadAd();
          onComplete();
        },
      );
      _interstitialAd!.show();
    } else {
      // Agar ad load nahi hui hai toh user ko roko mat, direct action karo
      onComplete();
      loadAd();
    }
  }
}