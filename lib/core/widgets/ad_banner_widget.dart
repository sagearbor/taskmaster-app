import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../di/service_locator.dart';
import '../services/ad_service.dart';

class AdBannerWidget extends StatefulWidget {
  final EdgeInsets? margin;
  final bool showCloseButton;

  const AdBannerWidget({
    super.key,
    this.margin,
    this.showCloseButton = false,
  });

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  bool _isAdDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    final adService = sl<AdService>();
    _bannerAd = adService.createBannerAd();
    
    _bannerAd!.listener = BannerAdListener(
      onAdLoaded: (ad) {
        setState(() {
          _isBannerAdReady = true;
        });
      },
      onAdFailedToLoad: (ad, error) {
        setState(() {
          _isBannerAdReady = false;
        });
        ad.dispose();
      },
      onAdOpened: (ad) {
        // Ad opened
      },
      onAdClosed: (ad) {
        // Ad closed
      },
    );

    _bannerAd!.load();
  }

  void _dismissAd() {
    setState(() {
      _isAdDismissed = true;
    });
    _bannerAd?.dispose();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdDismissed || !_isBannerAdReady || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          Container(
            alignment: Alignment.center,
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
          if (widget.showCloseButton)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: _dismissAd,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class InterstitialAdManager {
  static bool _isShowingAd = false;
  static int _adShowCount = 0;
  static const int _adFrequency = 3; // Show ad every 3 actions

  static Future<void> showAdIfNeeded({
    bool forceShow = false,
    VoidCallback? onAdDismissed,
  }) async {
    if (_isShowingAd) return;

    _adShowCount++;
    
    if (forceShow || _adShowCount >= _adFrequency) {
      _adShowCount = 0;
      await _showInterstitialAd(onAdDismissed: onAdDismissed);
    }
  }

  static Future<void> _showInterstitialAd({VoidCallback? onAdDismissed}) async {
    if (_isShowingAd) return;

    final adService = sl<AdService>();
    if (adService.isInterstitialAdReady) {
      _isShowingAd = true;
      await adService.showInterstitialAd();
      _isShowingAd = false;
      onAdDismissed?.call();
    }
  }

  static void resetAdCounter() {
    _adShowCount = 0;
  }
}

class RewardedAdDialog extends StatefulWidget {
  final String title;
  final String description;
  final String rewardDescription;
  final VoidCallback onRewardEarned;
  final VoidCallback? onAdDismissed;

  const RewardedAdDialog({
    super.key,
    required this.title,
    required this.description,
    required this.rewardDescription,
    required this.onRewardEarned,
    this.onAdDismissed,
  });

  @override
  State<RewardedAdDialog> createState() => _RewardedAdDialogState();
}

class _RewardedAdDialogState extends State<RewardedAdDialog> {
  bool _isLoadingAd = false;

  Future<void> _showRewardedAd() async {
    setState(() {
      _isLoadingAd = true;
    });

    final adService = sl<AdService>();
    
    if (adService.isRewardedAdReady) {
      Navigator.of(context).pop(); // Close dialog
      
      await adService.showRewardedAd(
        onRewardEarned: () {
          widget.onRewardEarned();
          widget.onAdDismissed?.call();
        },
      );
    } else {
      setState(() {
        _isLoadingAd = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad not ready. Please try again in a moment.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.card_giftcard, color: Colors.green[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.rewardDescription,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Maybe Later'),
        ),
        ElevatedButton(
          onPressed: _isLoadingAd ? null : _showRewardedAd,
          child: _isLoadingAd 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Watch Ad'),
        ),
      ],
    );
  }
}

class AdFreeBanner extends StatelessWidget {
  final VoidCallback? onUpgradePressed;

  const AdFreeBanner({
    super.key,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[400]!, Colors.purple[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.purple[200]!,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.star,
            color: Colors.yellow[300],
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Go Ad-Free!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Upgrade to Pro for an ad-free experience',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onUpgradePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow[300],
              foregroundColor: Colors.purple[800],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Upgrade',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}