import 'dart:async';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

abstract class AdService {
  Future<void> initialize();
  Future<void> loadInterstitialAd();
  Future<void> showInterstitialAd();
  Future<void> loadRewardedAd();
  Future<void> showRewardedAd({required Function onRewardEarned});
  BannerAd createBannerAd();
  bool get isInterstitialAdReady;
  bool get isRewardedAdReady;
  void dispose();
}

class AdServiceImpl implements AdService {
  static const String _androidBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // Test ID
  static const String _iosBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716'; // Test ID
  static const String _androidInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712'; // Test ID
  static const String _iosInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910'; // Test ID
  static const String _androidRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917'; // Test ID
  static const String _iosRewardedAdUnitId = 'ca-app-pub-3940256099942544/1712485313'; // Test ID

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialAdReady = false;
  bool _isRewardedAdReady = false;

  @override
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    
    // Load initial ads
    await loadInterstitialAd();
    await loadRewardedAd();
  }

  @override
  Future<void> loadInterstitialAd() async {
    final adUnitId = Platform.isAndroid 
        ? _androidInterstitialAdUnitId 
        : _iosInterstitialAdUnitId;

    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          
          _interstitialAd!.setImmersiveMode(true);
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd(); // Preload next ad
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd(); // Try to load again
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isInterstitialAdReady = false;
          // Retry after a delay
          Timer(const Duration(seconds: 30), () => loadInterstitialAd());
        },
      ),
    );
  }

  @override
  Future<void> showInterstitialAd() async {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      await _interstitialAd!.show();
    }
  }

  @override
  Future<void> loadRewardedAd() async {
    final adUnitId = Platform.isAndroid 
        ? _androidRewardedAdUnitId 
        : _iosRewardedAdUnitId;

    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          
          _rewardedAd!.setImmersiveMode(true);
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();
              _isRewardedAdReady = false;
              loadRewardedAd(); // Preload next ad
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              ad.dispose();
              _isRewardedAdReady = false;
              loadRewardedAd(); // Try to load again
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isRewardedAdReady = false;
          // Retry after a delay
          Timer(const Duration(seconds: 30), () => loadRewardedAd());
        },
      ),
    );
  }

  @override
  Future<void> showRewardedAd({required Function onRewardEarned}) async {
    if (_isRewardedAdReady && _rewardedAd != null) {
      await _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        onRewardEarned();
      });
    }
  }

  @override
  BannerAd createBannerAd() {
    final adUnitId = Platform.isAndroid 
        ? _androidBannerAdUnitId 
        : _iosBannerAdUnitId;

    return BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          // Banner ad loaded successfully
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
  }

  @override
  bool get isInterstitialAdReady => _isInterstitialAdReady;

  @override
  bool get isRewardedAdReady => _isRewardedAdReady;

  @override
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}

// Mock implementation for testing
class MockAdService implements AdService {
  bool _isInterstitialAdReady = true;
  bool _isRewardedAdReady = true;

  @override
  Future<void> initialize() async {
    // Mock initialization
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> loadInterstitialAd() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _isInterstitialAdReady = true;
  }

  @override
  Future<void> showInterstitialAd() async {
    if (_isInterstitialAdReady) {
      await Future.delayed(const Duration(seconds: 3)); // Simulate ad duration
      _isInterstitialAdReady = false;
      await loadInterstitialAd(); // Preload next
    }
  }

  @override
  Future<void> loadRewardedAd() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _isRewardedAdReady = true;
  }

  @override
  Future<void> showRewardedAd({required Function onRewardEarned}) async {
    if (_isRewardedAdReady) {
      await Future.delayed(const Duration(seconds: 30)); // Simulate ad duration
      onRewardEarned();
      _isRewardedAdReady = false;
      await loadRewardedAd(); // Preload next
    }
  }

  @override
  BannerAd createBannerAd() {
    // Return a mock banner ad (won't actually display in mock mode)
    return BannerAd(
      adUnitId: 'mock-banner-ad',
      request: const AdRequest(),
      size: AdSize.banner,
      listener: const BannerAdListener(),
    );
  }

  @override
  bool get isInterstitialAdReady => _isInterstitialAdReady;

  @override
  bool get isRewardedAdReady => _isRewardedAdReady;

  @override
  void dispose() {
    // Mock dispose
  }
}