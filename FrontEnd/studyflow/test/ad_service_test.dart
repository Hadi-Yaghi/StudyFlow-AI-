import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/config/ad_config.dart';
import 'package:studyflow/services/ad_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdConfig Tests', () {
    test('isTestMode returns true in test/debug mode', () {
      expect(AdConfig.isTestMode, isTrue);
    });

    test('Test Ad Unit IDs match official Google test IDs', () {
      expect(AdConfig.testAndroidBannerId, 'ca-app-pub-3940256099942544/6300978111');
      expect(AdConfig.testAndroidInterstitialId, 'ca-app-pub-3940256099942544/1033173712');
      expect(AdConfig.testIosBannerId, 'ca-app-pub-3940256099942544/2934735716');
      expect(AdConfig.testIosInterstitialId, 'ca-app-pub-3940256099942544/4411468910');
    });

    test('Thresholds and cooldown configurations are positive', () {
      expect(AdConfig.interstitialActionThreshold, greaterThan(0));
      expect(AdConfig.interstitialCooldown.inSeconds, greaterThan(0));
    });
  });

  group('AdService Logic Tests', () {
    final adService = AdService.instance;

    test('adsEnabled defaults to true', () {
      expect(adService.adsEnabled, isTrue);
    });

    test('adsEnabled can be toggled for premium users', () {
      adService.adsEnabled = false;
      expect(adService.adsEnabled, isFalse);

      // Re-enable for further testing
      adService.adsEnabled = true;
      expect(adService.adsEnabled, isTrue);
    });

    test('showInterstitialIfEligible returns false and invokes callback when ads disabled', () async {
      adService.adsEnabled = false;
      bool callbackInvoked = false;

      final result = await adService.showInterstitialIfEligible(
        actionContext: 'test_action',
        onAdClosed: () {
          callbackInvoked = true;
        },
      );

      expect(result, isFalse);
      expect(callbackInvoked, isTrue);

      adService.adsEnabled = true;
    });
  });
}
