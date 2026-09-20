import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/revenuecat_service.dart';

/// The StudyFlow-themed Premium subscription screen.
///
/// Features:
/// - Fully styled according to StudyFlow's indigo/purple design system
/// - Displays real, localized prices dynamically from RevenueCat Offerings
/// - Displays genuine store-configured free trial information without hardcoding
/// - Shows dynamically calculated yearly savings if prices permit
/// - Handles purchase, restore, and user cancellations gracefully
/// - Tailored UI for both Free and active Pro customers
/// - Integrates RevenueCat Paywalls and Customer Center
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final RevenueCatService _rcService = RevenueCatService.instance;

  Package? _selectedPackage;
  bool _isActionInProgress = false;

  @override
  void initState() {
    super.initState();
    _rcService.addListener(_onStateChanged);
    _selectInitialPackage();
  }

  @override
  void dispose() {
    _rcService.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {
        if (_selectedPackage == null) {
          _selectInitialPackage();
        }
      });
    }
  }

  void _selectInitialPackage() {
    // Default to Yearly for best value if available, else Monthly, else first package
    _selectedPackage = _rcService.yearlyPackage ??
        _rcService.monthlyPackage ??
        _rcService.lifetimePackage ??
        (_rcService.currentOffering?.availablePackages.isNotEmpty == true
            ? _rcService.currentOffering!.availablePackages.first
            : null);
  }

  Future<void> _handlePurchase() async {
    if (_selectedPackage == null) return;

    setState(() {
      _isActionInProgress = true;
    });

    final success = await _rcService.purchasePackage(_selectedPackage!);

    if (!mounted) return;

    setState(() {
      _isActionInProgress = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Welcome to StudyFlow Pro!'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 3),
        ),
      );
    } else if (_rcService.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_rcService.errorMessage!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleRestore() async {
    setState(() {
      _isActionInProgress = true;
    });

    final result = await _rcService.restorePurchases();

    if (!mounted) return;

    setState(() {
      _isActionInProgress = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? const Color(0xFF10B981) : const Color(0xFF6B7280),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPro = _rcService.isPro;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isActionInProgress ? null : _handleRestore,
            child: const Text(
              'Restore',
              style: TextStyle(
                color: Color(0xFF3525CD),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pro Crown Icon & Header
              _buildHeader(isDark, isPro),
              const SizedBox(height: 24),

              if (isPro) ...[
                // Already subscribed state
                _buildSubscribedCard(isDark),
                const SizedBox(height: 24),
              ] else ...[
                // Free user: feature benefits
                _buildBenefitsList(isDark),
                const SizedBox(height: 28),

                // Subscription Plan Cards
                _buildPlanSelectionSection(isDark),
                const SizedBox(height: 24),

                // Purchase CTA Button
                _buildPurchaseButton(),
                const SizedBox(height: 16),

                // Native RevenueCat Paywall option
                OutlinedButton.icon(
                  onPressed: _isActionInProgress
                      ? null
                      : () async {
                          await _rcService.presentPaywall();
                        },
                  icon: const Icon(Icons.style_outlined, size: 18),
                  label: const Text('View RevenueCat Native Paywall'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3525CD),
                    side: const BorderSide(color: Color(0xFF3525CD)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 46),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Legal / Terms info
              _buildTermsInfo(isDark),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, bool isPro) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF3525CD), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3525CD).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isPro ? 'StudyFlow Pro Active' : 'StudyFlow Pro',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF111827),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isPro
              ? 'You have unlimited access to all premium features.'
              : 'Study smarter. Stay focused. Unlock more.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscribedCard(bool isDark) {
    final status = _rcService.subscriptionStatus;
    final expFormatted = _rcService.formattedExpirationDate;

    final String badgeText;
    final Color badgeColor;
    final IconData badgeIcon;
    final String cardTitle;
    final String cardSubtitle;
    final String? dateLabel;

    switch (status) {
      case ProSubscriptionStatus.trial:
        badgeText = 'FREE TRIAL ACTIVE';
        badgeColor = const Color(0xFF10B981);
        badgeIcon = Icons.verified_rounded;
        cardTitle = 'Free Trial Active';
        cardSubtitle =
            'Your free trial is currently active with full Pro access and zero advertisements. '
            'Cancel anytime before the trial ends in Google Play to avoid charges.';
        dateLabel = expFormatted != null ? 'Trial Converts on: $expFormatted' : null;
        break;

      case ProSubscriptionStatus.cancelledActive:
        badgeText = 'CANCELLED (ACCESS ACTIVE)';
        badgeColor = const Color(0xFFF59E0B);
        badgeIcon = Icons.access_time_filled_rounded;
        cardTitle = 'Cancellation Scheduled';
        cardSubtitle =
            'Auto-renewal has been stopped. You will not be charged again, and you retain '
            'unlimited Pro access and zero ads until your current period concludes.';
        dateLabel = expFormatted != null ? 'Access Ends: $expFormatted' : null;
        break;

      case ProSubscriptionStatus.activePaid:
      default:
        badgeText = 'ACTIVE PRO';
        badgeColor = const Color(0xFF10B981);
        badgeIcon = Icons.check_circle_rounded;
        cardTitle = 'StudyFlow Pro Active';
        cardSubtitle =
            'You have unlimited access to all premium features, advanced study planning, and an ad-free experience.';
        dateLabel = expFormatted != null ? 'Next Billing Date: $expFormatted' : null;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151D2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 14, color: badgeColor),
                    const SizedBox(width: 5),
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                'studyflow_pro',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            cardTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            cardSubtitle,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          if (dateLabel != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade200 : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _rcService.presentCustomerCenter(),
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Manage Subscription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3525CD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsList(bool isDark) {
    final benefits = [
      (
        icon: Icons.block_flipped,
        title: 'No Ads',
        subtitle: 'Zero banner or interstitial interruptions while focusing',
        isComingSoon: false,
      ),
      (
        icon: Icons.cloud_upload_rounded,
        title: 'Course Material Uploads',
        subtitle: 'Upload and parse PDFs, Word docs, PPTX slides, and text files',
        isComingSoon: false,
      ),
      (
        icon: Icons.auto_awesome,
        title: 'AI-Assisted Study Planning',
        subtitle: 'AI document analysis to extract key topics and workload',
        isComingSoon: false,
      ),
      (
        icon: Icons.all_inclusive_rounded,
        title: 'Unlimited Schedule Generations',
        subtitle: 'Generate schedules freely without the Free 3-generation limit',
        isComingSoon: false,
      ),
      (
        icon: Icons.tune_rounded,
        title: 'Premium Scheduling Features',
        subtitle: 'Intelligent conflict resolution, break minutes, and workload balance',
        isComingSoon: false,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151D2E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: benefits.map((b) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEECFE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    b.icon,
                    size: 18,
                    color: const Color(0xFF3525CD),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              b.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          if (b.isComingSoon) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B),
                                  width: 0.8,
                                ),
                              ),
                              child: const Text(
                                'Coming Soon',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        b.subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlanSelectionSection(bool isDark) {
    final current = _rcService.currentOffering;

    if (_rcService.isLoading && current == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (current == null || current.availablePackages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151D2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Column(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 28),
            const SizedBox(height: 8),
            const Text(
              'No Offerings Available',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Please ensure a current Offering containing packages (monthly, yearly) is published in the RevenueCat dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    final monthly = _rcService.monthlyPackage;
    final yearly = _rcService.yearlyPackage;
    final lifetime = _rcService.lifetimePackage;

    final savingsTag = _rcService.getYearlySavingsPercentage();

    return Column(
      children: [
        if (yearly != null)
          _buildPackageCard(
            package: yearly,
            title: 'Annual / Yearly',
            subtitle: '${yearly.storeProduct.priceString} / year',
            badgeText: savingsTag ?? 'Best Value',
            badgeColor: const Color(0xFF10B981),
            isDark: isDark,
          ),
        if (monthly != null) ...[
          const SizedBox(height: 12),
          _buildPackageCard(
            package: monthly,
            title: 'Monthly',
            subtitle: '${monthly.storeProduct.priceString} / month',
            badgeText: null,
            badgeColor: null,
            isDark: isDark,
          ),
        ],
        if (lifetime != null) ...[
          const SizedBox(height: 12),
          _buildPackageCard(
            package: lifetime,
            title: 'Lifetime',
            subtitle: '${lifetime.storeProduct.priceString} one-time',
            badgeText: 'Pay Once',
            badgeColor: const Color(0xFF8B5CF6),
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  Widget _buildPackageCard({
    required Package package,
    required String title,
    required String subtitle,
    required String? badgeText,
    required Color? badgeColor,
    required bool isDark,
  }) {
    final isSelected = _selectedPackage?.identifier == package.identifier;
    final trialInfo = _rcService.getFreeTrialDescription(package);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackage = package;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E1B4B) : const Color(0xFFF5F3FF))
              : (isDark ? const Color(0xFF151D2E) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3525CD)
                : (isDark ? const Color(0xFF334155) : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF3525CD).withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Radio circle
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF3525CD) : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF3525CD),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),

            // Plan details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? const Color(0xFF3525CD)).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: badgeColor ?? const Color(0xFF3525CD),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3525CD),
                    ),
                  ),
                  if (trialInfo != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 13,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trialInfo,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton() {
    final trialDescription = _selectedPackage != null
        ? _rcService.getFreeTrialDescription(_selectedPackage!)
        : null;
    final bool hasTrial = trialDescription != null;
    final isLifetime = _selectedPackage?.packageType == PackageType.lifetime ||
        _selectedPackage?.identifier == 'lifetime';

    final String buttonLabel;
    if (hasTrial) {
      buttonLabel = trialDescription.contains('7-day')
          ? 'Start 7-Day Free Trial'
          : 'Start Free Trial';
    } else if (isLifetime) {
      buttonLabel = 'Unlock Lifetime Access';
    } else {
      buttonLabel = 'Upgrade to Pro';
    }

    final priceStr = _selectedPackage?.storeProduct.priceString ?? '';

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: (_isActionInProgress || _selectedPackage == null)
                ? null
                : _handlePurchase,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3525CD),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: _isActionInProgress
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        buttonLabel,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),

        if (hasTrial) ...[
          Text(
            '7 days free, then $priceStr / period. Cancel anytime in Google Play before the trial ends to avoid being charged.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3525CD),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Free trial available for eligible users. Google Play verifies eligibility at checkout.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 12, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              'Secure Google Play Billing. No card data touched by StudyFlow.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTermsInfo(bool isDark) {
    return Text(
      'Subscriptions renew automatically unless cancelled at least 24 hours before '
      'the end of the current period. Manage or cancel anytime in Google Play Subscriptions.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
      ),
    );
  }
}
