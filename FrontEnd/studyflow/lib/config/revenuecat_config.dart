import 'dart:io';
import 'package:flutter/foundation.dart';

/// Centralized configuration for RevenueCat in StudyFlow.
///
/// Ensures all product IDs, entitlement names, and API keys are maintained
/// in a single location following StudyFlow's architecture.
class RevenueCatConfig {
  RevenueCatConfig._();

  // ===========================================================================
  // ENTITLEMENTS & PRODUCTS
  // ===========================================================================

  /// The single canonical entitlement identifier that unlocks StudyFlow Pro.
  static const String proEntitlement = 'studyflow_pro';

  /// RevenueCat product identifier for Monthly subscription.
  static const String productMonthly = 'monthly';

  /// RevenueCat product identifier for Yearly subscription.
  static const String productYearly = 'yearly';

  /// RevenueCat product identifier for Lifetime non-renewing purchase.
  static const String productLifetime = 'lifetime';

  // ===========================================================================
  // TARGET PRICING (FOR VALIDATION & REPORTING ONLY)
  //
  // NOTE: Authoritative purchasing pricing is NEVER hardcoded; it is always
  // loaded dynamically from `Package.storeProduct.priceString`.
  // ===========================================================================
  static const double targetMonthlyPriceUsd = 1.50;
  static const double targetYearlyPriceUsd = 12.00;

  // ===========================================================================
  // REVENUECAT API KEYS
  // ===========================================================================

  /// Official Development / Test Store Public SDK API Key.
  /// Used for testing on Android / iOS / Test Store environments.
  static const String testStoreApiKey = 'test_YoNQjfnQUzAnfokPCDgtjJMqHzY';

  /// Public SDK key for Google Play Store.
  static const String prodGooglePlayApiKey = 'goog_YOUR_PRODUCTION_GOOGLE_PLAY_KEY';
  static String get googlePlayPublicApiKey => prodGooglePlayApiKey;

  /// Placeholder for Production Apple Public SDK Key.
  /// Can be overridden via `--dart-define=REVENUECAT_API_KEY=your_key`.
  static const String prodAppleApiKey = 'appl_YOUR_PRODUCTION_APPLE_KEY';

  static bool? _useGooglePlayOverride;

  /// Whether Google Play mode is enabled (via override or `--dart-define=USE_GOOGLE_PLAY=true`).
  static bool get useGooglePlay =>
      _useGooglePlayOverride ??
      const bool.fromEnvironment('USE_GOOGLE_PLAY', defaultValue: false);

  /// Allows toggling Google Play mode dynamically (useful in testing / debug settings).
  static void setGooglePlayMode(bool enable) {
    _useGooglePlayOverride = enable;
  }

  /// Resolves the appropriate RevenueCat Public SDK API Key.
  ///
  /// Priority:
  /// 1. `--dart-define=REVENUECAT_API_KEY=...` environment variable if present.
  /// 2. If [useGooglePlay] is true, returns [prodGooglePlayApiKey] for Android.
  /// 3. If in release mode, checks platform production key and warns if test key is used.
  /// 4. In debug / development mode, defaults safely to [testStoreApiKey].
  static String get apiKey {
    const envKey = String.fromEnvironment('REVENUECAT_API_KEY');
    if (envKey.isNotEmpty) {
      return envKey;
    }

    if (useGooglePlay) {
      if (Platform.isIOS) {
        return prodAppleApiKey;
      }
      return prodGooglePlayApiKey;
    }

    if (kReleaseMode) {
      if (Platform.isAndroid && !prodGooglePlayApiKey.startsWith('goog_YOUR_')) {
        return prodGooglePlayApiKey;
      } else if (Platform.isIOS && !prodAppleApiKey.startsWith('appl_YOUR_')) {
        return prodAppleApiKey;
      }

      if (kDebugMode) {
        debugPrint(
          '[RevenueCatConfig] WARNING: Running in release mode without a production '
          'RevenueCat key. Falling back to test store key.',
        );
      }
    }

    // Default development key (Test Store)
    return testStoreApiKey;
  }

  /// Whether the currently resolved key is a Test Store development key.
  static bool get isTestKey => apiKey.startsWith('test_');

  /// Returns a human-readable name of the active RevenueCat store environment.
  static String get activeEnvironmentName {
    if (isTestKey) return 'RevenueCat Test Store';
    if (apiKey.startsWith('goog_')) return 'Google Play Billing';
    if (apiKey.startsWith('appl_')) return 'Apple App Store';
    return 'Production Store';
  }
}
