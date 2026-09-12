import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/ad_config.dart';

/// Centralized service handling Google Mobile Ads (AdMob) in StudyFlow.
///
/// Features:
/// - Safe AdMob initialization without blocking app startup
/// - Preloading and lifecycle management for interstitial ads
/// - Built-in frequency capping (action threshold & cooldown timer)
/// - Safe error handling (never crashes on no fill or network drop)
/// - Future-proof [adsEnabled] toggle to disable all ads for Premium users
class AdService {
  AdService._internal();
  static final AdService instance = AdService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Global switch to control whether ads are served.
  /// When Premium is integrated later, simply do:
  /// `AdService.instance.adsEnabled = !isPremium;`
  bool adsEnabled = true;

  // Interstitial Ad state
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  int _actionCounter = 0;
  DateTime? _lastInterstitialShownTime;

  /// Number of eligible actions accumulated since the last interstitial.
  int get actionCounter => _actionCounter;

  /// Whether an interstitial ad is loaded and ready to be shown.
  bool get isInterstitialReady => _interstitialAd != null;

  /// Initializes the Google Mobile Ads SDK safely.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Mobile ads are supported on Android and iOS
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (kDebugMode) {
        debugPrint("[AdService] Platform ${Platform.operatingSystem} does not support MobileAds.");
      }
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      if (kDebugMode) {
        debugPrint("[AdService] MobileAds initialized successfully. Test mode: ${AdConfig.isTestMode}");
      }

      // Preload initial interstitial ad if ads are enabled
      if (adsEnabled) {
        preloadInterstitialAd();
      }
    } catch (e, stack) {
      // AdMob failure must NEVER crash StudyFlow or prevent users from using the app
      if (kDebugMode) {
        debugPrint("[AdService] MobileAds initialization failed: $e\n$stack");
      }
    }
  }

  /// Preloads an interstitial ad into memory if none is currently loaded.
  void preloadInterstitialAd() {
    if (!adsEnabled || !isPlatformSupported) return;
    if (_interstitialAd != null || _isInterstitialLoading) return;

    final adUnitId = AdConfig.interstitialAdUnitId;
    if (adUnitId.isEmpty) return;

    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          if (kDebugMode) {
            debugPrint("[AdService] Interstitial ad loaded successfully.");
          }
          _interstitialAd = ad;
          _isInterstitialLoading = false;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd dismissedAd) {
              if (kDebugMode) {
                debugPrint("[AdService] Interstitial ad dismissed by user.");
              }
              dismissedAd.dispose();
              _interstitialAd = null;
              // Preload the next one
              preloadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd failedAd, AdError error) {
              if (kDebugMode) {
                debugPrint("[AdService] Interstitial failed to show: ${error.message}");
              }
              failedAd.dispose();
              _interstitialAd = null;
              // Retry preload
              preloadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (kDebugMode) {
            debugPrint("[AdService] Interstitial ad failed to load: ${error.message} (code: ${error.code})");
          }
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  /// Evaluates whether an interstitial ad should be displayed based on:
  /// 1. [adsEnabled] is true
  /// 2. Action count reaches [AdConfig.interstitialActionThreshold]
  /// 3. Minimum cooldown time [AdConfig.interstitialCooldown] has elapsed
  /// 4. An interstitial ad is loaded and ready
  ///
  /// If conditions are satisfied, displays the ad and resets counter.
  /// If ad is not ready, triggers preloading and continues normal app flow.
  ///
  /// Returns `true` if an ad was displayed, `false` otherwise.
  Future<bool> showInterstitialIfEligible({
    required String actionContext,
    VoidCallback? onAdClosed,
  }) async {
    if (!adsEnabled || !isPlatformSupported) {
      onAdClosed?.call();
      return false;
    }

    _actionCounter++;
    if (kDebugMode) {
      debugPrint("[AdService] Eligible action recorded: '$actionContext'. Action count: $_actionCounter/${AdConfig.interstitialActionThreshold}");
    }

    // Check frequency counter threshold
    if (_actionCounter < AdConfig.interstitialActionThreshold) {
      if (_interstitialAd == null && !_isInterstitialLoading) {
        preloadInterstitialAd();
      }
      onAdClosed?.call();
      return false;
    }

    // Check cooldown period
    final now = DateTime.now();
    if (_lastInterstitialShownTime != null) {
      final elapsed = now.difference(_lastInterstitialShownTime!);
      if (elapsed < AdConfig.interstitialCooldown) {
        if (kDebugMode) {
          debugPrint("[AdService] Interstitial suppressed: cooldown active (${elapsed.inSeconds}s < ${AdConfig.interstitialCooldown.inSeconds}s).");
        }
        onAdClosed?.call();
        return false;
      }
    }

    // Check if an ad is ready to show
    if (_interstitialAd == null) {
      if (kDebugMode) {
        debugPrint("[AdService] Action threshold met, but interstitial ad was not ready. Preloading now.");
      }
      preloadInterstitialAd();
      onAdClosed?.call();
      return false;
    }

    // All conditions met: display interstitial
    final adToShow = _interstitialAd!;
    _interstitialAd = null; // Clear reference before showing to prevent reuse
    _actionCounter = 0;
    _lastInterstitialShownTime = now;

    // Attach custom dismiss callback if provided
    final previousCallback = adToShow.fullScreenContentCallback;
    adToShow.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        previousCallback?.onAdDismissedFullScreenContent?.call(ad);
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        previousCallback?.onAdFailedToShowFullScreenContent?.call(ad, error);
        onAdClosed?.call();
      },
      onAdShowedFullScreenContent: (ad) {
        previousCallback?.onAdShowedFullScreenContent?.call(ad);
      },
      onAdImpression: (ad) {
        previousCallback?.onAdImpression?.call(ad);
      },
      onAdClicked: (ad) {
        previousCallback?.onAdClicked?.call(ad);
      },
    );

    try {
      await adToShow.show();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("[AdService] Exception showing interstitial: $e");
      }
      adToShow.dispose();
      preloadInterstitialAd();
      onAdClosed?.call();
      return false;
    }
  }

  /// Convenience helper to create a managed [BannerAd] instance.
  BannerAd? createBannerAd({
    required BannerAdListener listener,
    AdSize size = AdSize.banner,
  }) {
    if (!adsEnabled || !isPlatformSupported) return null;

    final adUnitId = AdConfig.bannerAdUnitId;
    if (adUnitId.isEmpty) return null;

    return BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: listener,
    );
  }

  /// Checks if current platform supports Google Mobile Ads.
  bool get isPlatformSupported => Platform.isAndroid || Platform.isIOS;

  /// Disposes any loaded ads and cleans up resources.
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialLoading = false;
  }
}
