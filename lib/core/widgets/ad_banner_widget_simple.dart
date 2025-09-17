import 'package:flutter/material.dart';
import '../di/service_locator.dart';
import '../services/ad_service_simple.dart';

// Simplified ad banner for development
class AdBannerWidget extends StatelessWidget {
  final EdgeInsets? margin;
  final bool showCloseButton;

  const AdBannerWidget({
    super.key,
    this.margin,
    this.showCloseButton = false,
  });

  @override
  Widget build(BuildContext context) {
    // In development, show a placeholder
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: Text(
          'Ad Space - Ads disabled in development',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}

class InterstitialAdManager {
  static Future<void> showAdIfNeeded({
    bool forceShow = false,
    VoidCallback? onAdDismissed,
  }) async {
    // Mock implementation
    if (forceShow) {
      await Future.delayed(const Duration(seconds: 1));
      onAdDismissed?.call();
    }
  }

  static void resetAdCounter() {}
}

class RewardedAdDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(description),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Text(rewardDescription),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Simulate watching ad
            Future.delayed(const Duration(seconds: 2), () {
              onRewardEarned();
              onAdDismissed?.call();
            });
          },
          child: const Text('Watch Ad (Dev Mode)'),
        ),
      ],
    );
  }
}