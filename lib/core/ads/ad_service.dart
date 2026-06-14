import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static bool _initialized = false;
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdLoading = false;

  // Official AdMob Test Ad Unit IDs
  static String get bannerAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111'; // Android test banner
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716'; // iOS test banner
      }
    }
    // TODO: Replace with your real Production AdMob Unit IDs
    if (Platform.isAndroid) {
      return ''; 
    } else if (Platform.isIOS) {
      return '';
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/1033173712'; // Android test interstitial
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/4411468910'; // iOS test interstitial
      }
    }
    // TODO: Replace with your real Production AdMob Unit IDs
    if (Platform.isAndroid) {
      return '';
    } else if (Platform.isIOS) {
      return '';
    }
    return '';
  }

  // Initialize Mobile Ads SDK
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('AdMob SDK Initialized Successfully');
      // Pre-load an interstitial ad
      loadInterstitialAd();
    } catch (e) {
      debugPrint('AdMob SDK Initialization failed: $e');
    }
  }

  // Load Interstitial Ad
  static void loadInterstitialAd() {
    if (_isInterstitialAdLoading || interstitialAdUnitId.isEmpty) return;
    _isInterstitialAdLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              // Reload ad for next time
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              // Reload ad for next attempt
              loadInterstitialAd();
            },
          );
          debugPrint('Interstitial Ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial Ad failed to load: $error');
          _isInterstitialAdLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  // Show Interstitial Ad if ready, with dynamic callback
  static void showInterstitialAd({VoidCallback? onComplete}) {
    if (_interstitialAd != null) {
      // Setup temporary callback to execute action after ad concludes
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd();
          if (onComplete != null) onComplete();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd();
          if (onComplete != null) onComplete();
        },
      );
      _interstitialAd!.show();
    } else {
      debugPrint('Interstitial Ad not ready yet.');
      // Ad not ready, bypass the ad and execute standard flow directly
      loadInterstitialAd();
      if (onComplete != null) onComplete();
    }
  }
}
