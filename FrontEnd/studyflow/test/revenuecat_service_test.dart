import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/config/revenuecat_config.dart';
import 'package:studyflow/services/ad_service.dart';
import 'package:studyflow/services/revenuecat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RevenueCatConfig Tests', () {
    test('Entitlement and product IDs match specification', () {
      expect(RevenueCatConfig.proEntitlement, 'studyflow_pro');
      expect(RevenueCatConfig.productMonthly, 'monthly');
      expect(RevenueCatConfig.productYearly, 'yearly');
      expect(RevenueCatConfig.productLifetime, 'lifetime');
    });

    test('Test Store API key matches official development credential', () {
      expect(RevenueCatConfig.testStoreApiKey, 'test_YoNQjfnQUzAnfokPCDgtjJMqHzY');
    });

    test('Target prices are calibrated correctly for validation', () {
      expect(RevenueCatConfig.targetMonthlyPriceUsd, 1.50);
      expect(RevenueCatConfig.targetYearlyPriceUsd, 12.00);
    });

    test('Default API key resolves to test store key in debug/test mode', () {
      expect(RevenueCatConfig.apiKey, RevenueCatConfig.testStoreApiKey);
      expect(RevenueCatConfig.isTestKey, isTrue);
      expect(RevenueCatConfig.activeEnvironmentName, 'RevenueCat Test Store');
    });

    test('Environment configuration toggle switches between Test Store and Google Play', () {
      RevenueCatConfig.setGooglePlayMode(true);
      expect(RevenueCatConfig.useGooglePlay, isTrue);
      expect(RevenueCatConfig.apiKey, RevenueCatConfig.googlePlayPublicApiKey);
      expect(RevenueCatConfig.isTestKey, isFalse);
      expect(RevenueCatConfig.activeEnvironmentName, 'Google Play Billing');

      // Reset back to Test Store
      RevenueCatConfig.setGooglePlayMode(false);
      expect(RevenueCatConfig.useGooglePlay, isFalse);
      expect(RevenueCatConfig.apiKey, RevenueCatConfig.testStoreApiKey);
      expect(RevenueCatConfig.isTestKey, isTrue);
    });
  });

  group('RevenueCatService Logic Tests', () {
    final rcService = RevenueCatService.instance;
    final adService = AdService.instance;

    test('Default state is Free and not Pro', () {
      expect(rcService.isPro, isFalse);
      expect(rcService.hasProAccess(), isFalse);
      expect(rcService.subscriptionStatus, ProSubscriptionStatus.free);
      expect(rcService.isTrial, isFalse);
      expect(rcService.willRenew, isFalse);
      expect(rcService.formattedExpirationDate, isNull);
      expect(rcService.managementUrl, isNull);
    });

    test('Logout clears user identity and resets Pro state and re-enables ads', () async {
      await rcService.logOut();
      expect(rcService.isPro, isFalse);
      expect(rcService.currentUserId, isNull);
      expect(rcService.subscriptionStatus, ProSubscriptionStatus.free);
      expect(adService.adsEnabled, isTrue);
    });
  });
}
