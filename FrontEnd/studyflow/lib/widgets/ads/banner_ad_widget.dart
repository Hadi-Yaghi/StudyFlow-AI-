import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/ad_service.dart';

/// A reusable, self-contained Banner Ad widget for StudyFlow.
///
/// Features:
/// - Loads asynchronously without blocking the UI thread
/// - Renders [SizedBox.shrink] while loading or if loading fails (no blank gaps)
/// - Properly disposes [BannerAd] when the widget unmounts
/// - Automatically respects [AdService.instance.adsEnabled]
/// - Styled with subtle margin and borders to feel integrated into StudyFlow
class BannerAdWidget extends StatefulWidget {
  /// Optional margin around the banner ad container.
  final EdgeInsetsGeometry margin;

  /// Ad size for this banner. Defaults to standard [AdSize.banner] (320x50).
  final AdSize adSize;

  const BannerAdWidget({
    super.key,
    this.margin = const EdgeInsets.symmetric(vertical: 12),
    this.adSize = AdSize.banner,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _hasFailed = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    // If ads are disabled (e.g. Premium user) or platform is not supported, do not load
    if (!AdService.instance.adsEnabled || !AdService.instance.isPlatformSupported) {
      return;
    }

    final banner = AdService.instance.createBannerAd(
      size: widget.adSize,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
            _hasFailed = false;
          });
          if (kDebugMode) {
            debugPrint("[BannerAdWidget] Banner ad loaded successfully.");
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          if (kDebugMode) {
            debugPrint("[BannerAdWidget] Banner ad failed to load: ${error.message} (code: ${error.code})");
          }
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isLoaded = false;
              _hasFailed = true;
            });
          }
        },
      ),
    );

    if (banner != null) {
      banner.load();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If ads are disabled globally, or ad failed to load, or not yet loaded:
    // show NOTHING (zero space/no broken UI).
    if (!AdService.instance.adsEnabled || !_isLoaded || _hasFailed || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: widget.margin,
      alignment: Alignment.center,
      child: Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
