import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/revenuecat_config.dart';
import 'ad_service.dart';

/// Detailed subscription statuses reflecting the real Google Play / store state.
enum ProSubscriptionStatus {
  /// No active Pro entitlement.
  free,

  /// Active introductory or free trial period.
  trial,

  /// Active auto-renewing paid subscription.
  activePaid,

  /// User cancelled renewal, but access remains active until expiration date.
  cancelledActive,
}

/// Centralized service handling RevenueCat subscriptions, entitlements,
/// offerings, purchases, paywalls, and customer center in StudyFlow.
///
/// Implements [ChangeNotifier] for lightweight reactive updates across the app.
class RevenueCatService extends ChangeNotifier {
  RevenueCatService._internal();
  static final RevenueCatService instance = RevenueCatService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isPro = false;
  /// Canonical source of truth for StudyFlow Pro status.
  bool get isPro => _isPro;

  CustomerInfo? _customerInfo;
  CustomerInfo? get customerInfo => _customerInfo;

  Offerings? _offerings;
  Offerings? get offerings => _offerings;

  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Returns the active 'studyflow_pro' EntitlementInfo if active.
  EntitlementInfo? get proEntitlement =>
      _customerInfo?.entitlements.all[RevenueCatConfig.proEntitlement];

  /// Returns true if the user is currently enjoying an active free trial.
  bool get isTrial {
    if (!_isPro) return false;
    final ent = proEntitlement;
    return ent?.periodType == PeriodType.trial || ent?.periodType == PeriodType.intro;
  }

  /// Returns true if the subscription is set to renew at the end of the billing period.
  /// If false, the customer has cancelled renewal, but retains Pro access until expiration.
  bool get willRenew {
    if (!_isPro) return false;
    return proEntitlement?.willRenew ?? false;
  }

  /// Resolves the current structured subscription status.
  ProSubscriptionStatus get subscriptionStatus {
    if (!_isPro) return ProSubscriptionStatus.free;
    final ent = proEntitlement;
    if (ent == null) return ProSubscriptionStatus.free;

    // User cancelled in Customer Center or Google Play, but access remains active
    if (ent.willRenew == false) {
      return ProSubscriptionStatus.cancelledActive;
    }

    if (ent.periodType == PeriodType.trial || ent.periodType == PeriodType.intro) {
      return ProSubscriptionStatus.trial;
    }

    return ProSubscriptionStatus.activePaid;
  }

  /// Returns a clean formatted expiration / renewal date (YYYY-MM-DD) from RevenueCat.
  String? get formattedExpirationDate {
    final exp = proEntitlement?.expirationDate;
    if (exp == null || exp.isEmpty) return null;
    final dt = DateTime.tryParse(exp);
    if (dt != null) {
      final local = dt.toLocal();
      return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    }
    return exp.split('T')[0];
  }

  /// Store subscription management URL provided by RevenueCat (e.g. Google Play Subscriptions link).
  String? get managementUrl => _customerInfo?.managementURL;

  /// Safely opens the store subscription management URL in external application/browser.
  Future<bool> openManagementUrl() async {
    final urlStr = managementUrl;
    if (urlStr == null || urlStr.isEmpty) return false;
    try {
      final uri = Uri.tryParse(urlStr);
      if (uri != null && await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RevenueCatService] Error opening management URL: $e');
      }
    }
    return false;
  }


  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  /// Configures RevenueCat SDK once at application launch.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // RevenueCat mobile SDK supports Android and iOS
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (kDebugMode) {
        debugPrint('[RevenueCatService] Platform ${Platform.operatingSystem} does not support RevenueCat SDK.');
      }
      return;
    }

    try {
      final apiKey = RevenueCatConfig.apiKey;
      if (kDebugMode) {
        debugPrint('[RevenueCatService] Initializing RevenueCat with key prefix: ${apiKey.substring(0, apiKey.length > 5 ? 5 : apiKey.length)}...');
        await Purchases.setLogLevel(LogLevel.debug);
      }

      final configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);

      // Listen for real-time CustomerInfo updates (e.g. renewal, cancellation, webhooks)
      Purchases.addCustomerInfoUpdateListener((CustomerInfo info) {
        _handleCustomerInfoUpdate(info);
      });

      _isInitialized = true;

      // Load initial customer info
      await refreshCustomerInfo();

      // Load initial offerings
      await loadOfferings();
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[RevenueCatService] Initialization failed: $e\n$stack');
      }
      _errorMessage = 'Failed to initialize subscription service.';
    }
  }

  // ===========================================================================
  // CUSTOMER INFO & ENTITLEMENTS
  // ===========================================================================

  /// Refreshes the latest [CustomerInfo] directly from RevenueCat.
  Future<CustomerInfo?> refreshCustomerInfo() async {
    if (!_isInitialized) return null;

    try {
      _isLoading = true;
      notifyListeners();

      final info = await Purchases.getCustomerInfo();
      _handleCustomerInfoUpdate(info);
      return info;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RevenueCatService] Error fetching customer info: $e');
      }
      return _customerInfo;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Canonical check: returns true if the 'studyflow_pro' entitlement is active.
  bool hasProAccess() {
    return _isPro;
  }

  void _handleCustomerInfoUpdate(CustomerInfo info) {
    _customerInfo = info;
    final entitlement = info.entitlements.all[RevenueCatConfig.proEntitlement];
    final bool proActive = entitlement?.isActive == true;

    final bool proChanged = _isPro != proActive;
    _isPro = proActive;

    // Immediately synchronize AdMob suppression
    AdService.instance.adsEnabled = !_isPro;

    if (kDebugMode) {
      debugPrint('[RevenueCatService] CustomerInfo updated. Pro active: $_isPro (Entitlement: ${RevenueCatConfig.proEntitlement})');
    }

    if (proChanged) {
      notifyListeners();
    }
  }

  // ===========================================================================
  // USER IDENTITY LIFECYCLE (LOGIN / LOGOUT)
  // ===========================================================================

  /// Identifies the RevenueCat customer with a stable StudyFlow user ID.
  ///
  /// Format: `studyflow_$userId` (e.g. `studyflow_42`).
  Future<void> logIn(dynamic userId) async {
    if (!_isInitialized || userId == null) return;

    final appUserId = 'studyflow_$userId';
    if (_currentUserId == appUserId) {
      // Already logged in as this user
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final result = await Purchases.logIn(appUserId);
      _currentUserId = appUserId;
      _handleCustomerInfoUpdate(result.customerInfo);

      if (kDebugMode) {
        debugPrint('[RevenueCatService] Logged in to RevenueCat as $appUserId. Pro: $_isPro');
      }

      // Refresh offerings for this customer
      await loadOfferings();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RevenueCatService] Failed to log in as $appUserId: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logs out of RevenueCat and immediately resets local Pro state.
  ///
  /// This guarantees that User B will never inherit User A's Pro access.
  Future<void> logOut() async {
    if (!_isInitialized) return;

    try {
      _isLoading = true;
      // Immediately reset local state for complete user isolation
      _isPro = false;
      _currentUserId = null;
      _customerInfo = null;
      AdService.instance.adsEnabled = true;
      notifyListeners();

      await Purchases.logOut();

      if (kDebugMode) {
        debugPrint('[RevenueCatService] Logged out from RevenueCat.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RevenueCatService] Error during logout: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // OFFERINGS & PACKAGES
  // ===========================================================================

  /// Fetches available Offerings from RevenueCat.
  Future<Offerings?> loadOfferings() async {
    if (!_isInitialized) return null;

    try {
      final offerings = await Purchases.getOfferings();
      _offerings = offerings;
      _errorMessage = null;

      if (kDebugMode) {
        final current = offerings.current;
        debugPrint('[RevenueCatService] Loaded offerings. Current: ${current?.identifier}');
        if (current != null) {
          for (final pkg in current.availablePackages) {
            debugPrint('  - Package: ${pkg.identifier}, Product: ${pkg.storeProduct.identifier}, Price: ${pkg.storeProduct.priceString}');
          }
        }
      }

      notifyListeners();
      return offerings;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RevenueCatService] Error loading offerings: $e');
      }
      _errorMessage = 'Unable to load subscription plans.';
      notifyListeners();
      return null;
    }
  }

  /// The current / default Offering configured in the RevenueCat dashboard.
  Offering? get currentOffering => _offerings?.current;

  /// Resolves the Monthly package safely by package type or product identifier.
  Package? get monthlyPackage {
    final current = currentOffering;
    if (current == null) return null;

    // Check predefined monthly package slot
    if (current.monthly != null) return current.monthly;

    // Search available packages by type or product identifier
    for (final pkg in current.availablePackages) {
      if (pkg.packageType == PackageType.monthly ||
          pkg.storeProduct.identifier == RevenueCatConfig.productMonthly ||
          pkg.identifier == RevenueCatConfig.productMonthly) {
        return pkg;
      }
    }
    return null;
  }

  /// Resolves the Yearly / Annual package safely by package type or product identifier.
  Package? get yearlyPackage {
    final current = currentOffering;
    if (current == null) return null;

    // Check predefined annual package slot
    if (current.annual != null) return current.annual;

    // Search available packages by type or product identifier
    for (final pkg in current.availablePackages) {
      if (pkg.packageType == PackageType.annual ||
          pkg.storeProduct.identifier == RevenueCatConfig.productYearly ||
          pkg.identifier == RevenueCatConfig.productYearly) {
        return pkg;
      }
    }
    return null;
  }

  /// Resolves the Lifetime package safely by package type or product identifier.
  Package? get lifetimePackage {
    final current = currentOffering;
    if (current == null) return null;

    // Check predefined lifetime package slot
    if (current.lifetime != null) return current.lifetime;

    // Search available packages by type or product identifier
    for (final pkg in current.availablePackages) {
      if (pkg.packageType == PackageType.lifetime ||
          pkg.storeProduct.identifier == RevenueCatConfig.productLifetime ||
          pkg.identifier == RevenueCatConfig.productLifetime) {
        return pkg;
      }
    }
    return null;
  }

  // ===========================================================================
  // PURCHASING & RESTORING
  // ===========================================================================

  /// Purchases the specified [Package] using the modern RevenueCat PurchaseParams API.
  ///
  /// Returns `true` if Pro access was successfully unlocked, `false` otherwise.
  Future<bool> purchasePackage(Package package) async {
    if (!_isInitialized) {
      _errorMessage = 'Subscription service is not ready.';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final params = PurchaseParams.package(package);
      final result = await Purchases.purchase(params);

      _handleCustomerInfoUpdate(result.customerInfo);

      // Verify canonical entitlement
      final isUnlocked = result.customerInfo.entitlements.all[RevenueCatConfig.proEntitlement]?.isActive == true;
      return isUnlocked;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        if (kDebugMode) {
          debugPrint('[RevenueCatService] User cancelled the purchase flow.');
        }
        // Do not set error message or show dialog for user cancellation
        return false;
      }

      if (kDebugMode) {
        debugPrint('[RevenueCatService] Purchase error: [${errorCode.name}] ${e.message}');
      }
      _errorMessage = _mapPurchaseErrorMessage(errorCode, e.message);
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RevenueCatService] Unexpected purchase error: $e');
      }
      _errorMessage = 'Purchase could not be completed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Restores previous purchases for the authenticated customer.
  ///
  /// Returns a record with `success` (whether Pro is active) and `message` for UI feedback.
  Future<({bool success, String message})> restorePurchases() async {
    if (!_isInitialized) {
      return (success: false, message: 'Subscription service is not ready.');
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final customerInfo = await Purchases.restorePurchases();
      _handleCustomerInfoUpdate(customerInfo);

      final isUnlocked = customerInfo.entitlements.all[RevenueCatConfig.proEntitlement]?.isActive == true;

      if (isUnlocked) {
        return (success: true, message: 'StudyFlow Pro restored successfully!');
      } else {
        return (success: false, message: 'No active purchases were found.');
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      final message = _mapPurchaseErrorMessage(errorCode, e.message);
      return (success: false, message: message);
    } catch (e) {
      return (success: false, message: 'Failed to restore purchases. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _mapPurchaseErrorMessage(PurchasesErrorCode code, String? fallback) {
    switch (code) {
      case PurchasesErrorCode.networkError:
        return 'Network error. Please check your internet connection.';
      case PurchasesErrorCode.storeProblemError:
        return 'The app store is currently unavailable. Please try again later.';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'Purchases are not allowed on this device or account.';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        return 'This product is currently unavailable.';
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return 'You have already purchased this item. Try restoring purchases.';
      case PurchasesErrorCode.paymentPendingError:
        return 'Your payment is pending confirmation by the store.';
      default:
        return fallback ?? 'An unexpected error occurred during purchase.';
    }
  }

  // ===========================================================================
  // REVENUECAT UI: PAYWALLS & CUSTOMER CENTER
  // ===========================================================================

  /// Presents the RevenueCat Paywall modally.
  Future<PaywallResult> presentPaywall() async {
    if (!_isInitialized) return PaywallResult.notPresented;

    try {
      final result = await RevenueCatUI.presentPaywall();
      await refreshCustomerInfo();
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RevenueCatService] Error presenting paywall: $e');
      }
      return PaywallResult.error;
    }
  }

  /// Presents the RevenueCat Paywall ONLY IF 'studyflow_pro' is not already active.
  Future<PaywallResult> presentPaywallIfNeeded() async {
    if (!_isInitialized) return PaywallResult.notPresented;

    try {
      final result = await RevenueCatUI.presentPaywallIfNeeded(
        RevenueCatConfig.proEntitlement,
      );
      await refreshCustomerInfo();
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RevenueCatService] Error presenting paywall if needed: $e');
      }
      return PaywallResult.error;
    }
  }

  /// Presents the RevenueCat Customer Center for subscription management.
  /// Falls back to the store management URL if Customer Center fails.
  Future<void> presentCustomerCenter() async {
    if (!_isInitialized) return;

    try {
      await RevenueCatUI.presentCustomerCenter(
        onRestoreCompleted: (customerInfo) {
          _handleCustomerInfoUpdate(customerInfo);
        },
      );
      await refreshCustomerInfo();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RevenueCatService] Error presenting Customer Center: $e. Falling back to management URL.');
      }
      await openManagementUrl();
    }
  }

  // ===========================================================================
  // PRICING & FREE TRIAL HELPERS
  // ===========================================================================

  /// Dynamically calculates yearly savings percentage compared to paying monthly for 12 months.
  ///
  /// Returns a string such as `'Save 33%'`, or `null` if prices cannot be compared.
  String? getYearlySavingsPercentage() {
    final monthly = monthlyPackage;
    final yearly = yearlyPackage;
    if (monthly == null || yearly == null) return null;

    final mPrice = monthly.storeProduct.price;
    final yPrice = yearly.storeProduct.price;

    if (mPrice <= 0 || yPrice <= 0) return null;

    // Verify same currency
    if (monthly.storeProduct.currencyCode != yearly.storeProduct.currencyCode) {
      return null;
    }

    final annualIfMonthly = mPrice * 12.0;
    if (yPrice >= annualIfMonthly) return null;

    final savingFraction = (annualIfMonthly - yPrice) / annualIfMonthly;
    final savingPercent = (savingFraction * 100).round();

    if (savingPercent <= 0) return null;
    return 'Save $savingPercent%';
  }

  /// Extracts truthful free trial information for a given [Package].
  ///
  /// Returns descriptive text (e.g. `'7-day free trial'`) or `null` if no free trial is attached.
  String? getFreeTrialDescription(Package package) {
    final product = package.storeProduct;

    // 1. Inspect subscription options (modern Android Google Play Billing)
    final options = product.subscriptionOptions;
    if (options != null && options.isNotEmpty) {
      for (final option in options) {
        final freePhase = option.freePhase;
        if (freePhase != null) {
          final period = freePhase.billingPeriod;
          return _formatPeriodDescription(period);
        }
      }
    }

    // 2. Inspect defaultOption
    final defaultFree = product.defaultOption?.freePhase;
    if (defaultFree != null) {
      return _formatPeriodDescription(defaultFree.billingPeriod);
    }

    // 3. Fallback: check legacy introductoryPrice
    final intro = product.introductoryPrice;
    if (intro != null && intro.price == 0) {
      return _formatIsoPeriodString(intro.period);
    }

    return null;
  }

  String _formatIsoPeriodString(String? iso) {
    if (iso == null || iso.isEmpty) return 'Free trial available';
    final upper = iso.toUpperCase();
    if (upper == 'P1W' || upper == 'P7D') return '7-day free trial';
    if (upper == 'P14D' || upper == 'P2W') return '14-day free trial';
    if (upper == 'P1M') return '1-month free trial';
    if (upper == 'P3M') return '3-month free trial';
    if (upper == 'P1Y') return '1-year free trial';
    return 'Free trial available';
  }

  String _formatPeriodDescription(Period? period) {
    if (period == null) return 'Free trial available';

    final unit = period.unit;
    final value = period.value;

    switch (unit) {
      case PeriodUnit.day:
        return value == 1 ? '1-day free trial' : '$value-day free trial';
      case PeriodUnit.week:
        return value == 1 ? '7-day free trial' : '${value * 7}-day free trial';
      case PeriodUnit.month:
        return value == 1 ? '1-month free trial' : '$value-month free trial';
      case PeriodUnit.year:
        return value == 1 ? '1-year free trial' : '$value-year free trial';
      default:
        return 'Free trial available';
    }
  }
}
