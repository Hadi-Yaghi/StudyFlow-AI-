import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../core/network/api_client.dart';
import 'revenuecat_service.dart';

/// Centralized service governing plan capabilities and feature gating in StudyFlow.
///
/// Single source of truth for Pro is the RevenueCat entitlement `studyflow_pro`.
class FeatureAccessService extends ChangeNotifier {
  FeatureAccessService._internal() {
    RevenueCatService.instance.addListener(_onRevenueCatChanged);
  }

  static final FeatureAccessService instance = FeatureAccessService._internal();

  static const int freeScheduleGenerationLimit = 3;

  final ApiClient _apiClient = ApiClient();
  int _remainingFreeGenerations = freeScheduleGenerationLimit;
  int _usedFreeGenerations = 0;
  String _quotaPeriod = 'MONTHLY';
  bool _isLoadingUsage = false;

  /// Canonical source of truth: whether RevenueCat entitlement `studyflow_pro` is active.
  bool get isPro => RevenueCatService.instance.isPro;

  /// Course file upload is restricted strictly to StudyFlow Pro users.
  bool get canUploadCourseFiles => isPro;

  /// AI study planning and analysis is strictly restricted to StudyFlow Pro users.
  bool get canUseAi => isPro;

  /// AI schedule generation is strictly restricted to StudyFlow Pro users.
  bool get canGenerateWithAi => isPro;

  /// Remaining free schedule generations within the current quota period.
  int get remainingFreeScheduleGenerations => isPro ? -1 : _remainingFreeGenerations;

  /// Free generations used in current period.
  int get usedFreeScheduleGenerations => _usedFreeGenerations;

  /// Current quota period from backend (e.g. MONTHLY).
  String get quotaPeriod => _quotaPeriod;

  /// Whether the user can currently trigger a schedule generation.
  bool get canGenerateSchedule => isPro || _remainingFreeGenerations > 0;

  bool get isLoadingUsage => _isLoadingUsage;

  void _onRevenueCatChanged() {
    notifyListeners();
    // Sync backend when subscription state changes
    syncSubscriptionWithBackend();
  }

  /// Refreshes generation usage from the backend.
  Future<void> refreshScheduleUsage() async {
    try {
      _isLoadingUsage = true;
      notifyListeners();

      final response = await _apiClient.dio.get(
        ApiConfig.scheduleUsageUrl,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        _remainingFreeGenerations = data['remainingGenerations'] as int? ?? 0;
        _usedFreeGenerations = data['usedGenerations'] as int? ?? 0;
        _quotaPeriod = data['quotaPeriod'] as String? ?? 'MONTHLY';
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FeatureAccessService] Error refreshing schedule usage: $e');
      }
    } finally {
      _isLoadingUsage = false;
      notifyListeners();
    }
  }

  /// Updates remaining generations directly after a scheduler response.
  void updateFromSchedulerResult({
    required int remaining,
    required int used,
  }) {
    if (remaining >= 0) {
      _remainingFreeGenerations = remaining;
    }
    _usedFreeGenerations = used;
    notifyListeners();
  }

  /// Synchronizes subscription state with the Spring Boot backend.
  Future<void> syncSubscriptionWithBackend() async {
    try {
      final isCurrentlyPro = isPro;
      final ent = RevenueCatService.instance.proEntitlement;

      await _apiClient.dio.post(
        ApiConfig.subscriptionSyncUrl,
        data: {
          'isPro': isCurrentlyPro,
          'productId': ent?.productIdentifier ?? (isCurrentlyPro ? 'pro' : 'free'),
          'expiresAt': ent?.expirationDate,
        },
      );

      if (kDebugMode) {
        debugPrint('[FeatureAccessService] Successfully synced subscription with backend (isPro: $isCurrentlyPro)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FeatureAccessService] Failed to sync subscription with backend: $e');
      }
    }
  }
}
