import 'dart:async';

abstract class AdService {
  Future<void> initialize();
  Future<void> loadInterstitialAd();
  Future<void> showInterstitialAd();
  Future<void> loadRewardedAd();
  Future<void> showRewardedAd({required Function onRewardEarned});
  bool get isInterstitialAdReady;
  bool get isRewardedAdReady;
  void dispose();
}

// Mock implementation for development/testing
class MockAdService implements AdService {
  bool _isInterstitialAdReady = true;
  bool _isRewardedAdReady = true;

  @override
  Future<void> initialize() async {
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
      await Future.delayed(const Duration(seconds: 3));
      _isInterstitialAdReady = false;
      await loadInterstitialAd();
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
      await Future.delayed(const Duration(seconds: 5));
      onRewardEarned();
      _isRewardedAdReady = false;
      await loadRewardedAd();
    }
  }

  @override
  bool get isInterstitialAdReady => _isInterstitialAdReady;

  @override
  bool get isRewardedAdReady => _isRewardedAdReady;

  @override
  void dispose() {}
}

// Placeholder for real implementation
class AdServiceImpl extends MockAdService {
  // Will be implemented when google_mobile_ads is added
}