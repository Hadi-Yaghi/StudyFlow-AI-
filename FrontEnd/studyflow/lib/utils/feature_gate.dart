import 'package:flutter/material.dart';
import '../screens/premium_screen.dart';
import '../services/feature_access_service.dart';
import '../services/revenuecat_service.dart';

/// Reusable utility to gate StudyFlow Pro features across the application.
class FeatureGate {
  FeatureGate._();

  static FeatureAccessService get access => FeatureAccessService.instance;

  /// Checks whether StudyFlow Pro is active. If active, runs [onUnlocked].
  ///
  /// If not active, presents the RevenueCat Paywall or navigates to PremiumScreen.
  /// If the user completes purchase during the paywall presentation,
  /// [onUnlocked] is executed immediately upon return.
  static Future<void> requirePro(
    BuildContext context, {
    required VoidCallback onUnlocked,
    String? featureName,
  }) async {
    final revenueCat = RevenueCatService.instance;

    if (revenueCat.isPro) {
      onUnlocked();
      return;
    }

    // Try presenting native RevenueCat Paywall first
    await revenueCat.presentPaywallIfNeeded();

    if (revenueCat.isPro) {
      onUnlocked();
      return;
    }

    // If paywall wasn't presented or user dismissed without upgrading,
    // offer navigating to the rich custom PremiumScreen if still not pro
    if (!revenueCat.isPro && context.mounted) {
      final upgraded = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      );
      if (upgraded == true || revenueCat.isPro) {
        onUnlocked();
      }
    }
  }

  /// Displays the official StudyFlow Free Schedule Generation Limit Reached dialog.
  static void showScheduleLimitReachedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Free Limit Reached',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          "You've used your free schedule generations for this period.\n\nUpgrade to StudyFlow Pro for unlimited schedule generations, course file uploads, and AI study planning!",
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PremiumScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Upgrade to Pro'),
          ),
        ],
      ),
    );
  }

  /// Convenience synchronous check for widget builders.
  static bool get isPro => RevenueCatService.instance.isPro;
}
