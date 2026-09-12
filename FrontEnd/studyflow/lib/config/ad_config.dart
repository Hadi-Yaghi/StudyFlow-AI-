import 'dart:io';
import 'package:flutter/foundation.dart';

/// Configuration for Google Mobile Ads (AdMob) in StudyFlow.
///
/// Centralizes all Ad Unit IDs, test mode settings, and frequency thresholds.
/// During development, Google's official test ad unit IDs are always served.
class AdConfig {
  AdConfig._();

  /// When true, forces the app to serve Google's official test ads
  /// regardless of build mode.
  /// Set to false only when ready to release with production AdMob credentials.
  static const bool forceTestAds = true;

  // ===========================================================================
  // PRODUCTION AD UNIT IDs
  // Replace these placeholders with your actual AdMob IDs created in the
  // Google AdMob Console (https://admob.google.com) before releasing to stores.
  // ===========================================================================
  static const String prodAndroidBannerId = 'ca-app-pub-2857572493568967/4671270491';
  static const String prodAndroidInterstitialId = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';

  static const String prodIosBannerId = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
  static const String prodIosInterstitialId = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';

  // ===========================================================================
  // GOOGLE OFFICIAL TEST AD UNIT IDs
  // See: https://developers.google.com/admob/flutter/test-ads
  // ===========================================================================
  static const String testAndroidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testAndroidInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  static const String testIosBannerId = 'ca-app-pub-3940256099942544/2934735716';
  static const String testIosInterstitialId = 'ca-app-pub-3940256099942544/4411468910';

  // ===========================================================================
  // APP IDs (For reference; configured in AndroidManifest.xml & Info.plist)
  // ===========================================================================
  static const String testAndroidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String testIosAppId = 'ca-app-pub-3940256099942544~1458002511';

  /// Resolves whether the application should serve test advertisements.
  /// Guaranteed true if running in debug mode or if [forceTestAds] is true.
  static bool get isTestMode => kDebugMode || forceTestAds;

  /// Returns the appropriate Banner Ad Unit ID based on platform & environment.
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return isTestMode ? testAndroidBannerId : prodAndroidBannerId;
    } else if (Platform.isIOS) {
      return isTestMode ? testIosBannerId : prodIosBannerId;
    }
    return '';
  }

  /// Returns the appropriate Interstitial Ad Unit ID based on platform & environment.
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return isTestMode ? testAndroidInterstitialId : prodAndroidInterstitialId;
    } else if (Platform.isIOS) {
      return isTestMode ? testIosInterstitialId : prodIosInterstitialId;
    }
    return '';
  }

  // ===========================================================================
  // INTERSTITIAL FREQUENCY CONTROL
  // ===========================================================================

  /// Number of eligible actions required before an interstitial ad can be displayed.
  /// (e.g., 3 eligible actions such as creating tasks or generating schedules).
  static const int interstitialActionThreshold = 3;

  /// Minimum time cooldown between interstitial ad displays to prevent spamming users.
  static const Duration interstitialCooldown = Duration(minutes: 2);
}
