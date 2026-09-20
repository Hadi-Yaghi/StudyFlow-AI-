import 'package:flutter/material.dart';
import '../core/localization/locale_controller.dart';
import '../core/storage/token_storage.dart';
import '../core/theme/theme_controller.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/user_settings_service.dart';
import '../widgets/home_header.dart';
import '../widgets/profile_option_tile.dart';
import 'account_settings_screen.dart';
import 'availability_settings_screen.dart';
import 'login_screen.dart';
import 'premium_screen.dart';
import 'study_preferences_screen.dart';
import '../services/notification_service.dart';
import '../services/revenuecat_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final UserSettingsService _settingsService = UserSettingsService();

  String _userName = "Student";
  String _userEmail = "";
  String _userMajor = "Computer Science Major";

  bool _notificationsEnabled = true;
  bool _studyReminders = true;
  bool _taskDeadlines = true;

  @override
  void initState() {
    super.initState();
    RevenueCatService.instance.addListener(_onRcStateChanged);
    _loadUser();
    _loadSettings();
  }

  @override
  void dispose() {
    RevenueCatService.instance.removeListener(_onRcStateChanged);
    super.dispose();
  }

  void _onRcStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadUser() async {
    final userData = await TokenStorage.getUserData();
    if (mounted) {
      setState(() {
        if (userData['name'] != null && userData['name']!.isNotEmpty) {
          _userName = userData['name']!;
        }
        if (userData['email'] != null && userData['email']!.isNotEmpty) {
          _userEmail = userData['email']!;
        }
        if (userData['major'] != null && userData['major']!.isNotEmpty) {
          _userMajor = userData['major']!;
        }
      });
    }

    try {
      final profile = await _userService.getProfile();
      if (mounted) {
        setState(() {
          if (profile['name'] != null) _userName = profile['name'];
          if (profile['email'] != null) _userEmail = profile['email'];
          if (profile['major'] != null && profile['major'].toString().isNotEmpty) {
            _userMajor = profile['major'];
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.getSettings();
      if (mounted) {
        setState(() {
          _notificationsEnabled = settings['notificationsEnabled'] ?? true;
          _studyReminders = settings['studyReminders'] ?? true;
          _taskDeadlines = settings['taskDeadlines'] ?? true;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showNotificationSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151D2E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notification Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Enable Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Master switch for StudyFlow alerts'),
                    value: _notificationsEnabled,
                    activeTrackColor: const Color(0xFF3525CD),
                    onChanged: (val) {
                      setModalState(() => _notificationsEnabled = val);
                      setState(() => _notificationsEnabled = val);
                      _settingsService.updateSettings(notificationsEnabled: val);
                      NotificationService.instance.syncNotificationsWithDatabase();
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Study Reminders'),
                    subtitle: const Text('Alerts before scheduled study sessions'),
                    value: _notificationsEnabled && _studyReminders,
                    activeTrackColor: const Color(0xFF3525CD),
                    onChanged: _notificationsEnabled
                        ? (val) {
                            setModalState(() => _studyReminders = val);
                            setState(() => _studyReminders = val);
                            _settingsService.updateSettings(studyReminders: val);
                            NotificationService.instance.syncNotificationsWithDatabase();
                          }
                        : null,
                  ),
                  SwitchListTile(
                    title: const Text('Task & Deadline Reminders'),
                    subtitle: const Text('Alerts for upcoming due dates'),
                    value: _notificationsEnabled && _taskDeadlines,
                    activeTrackColor: const Color(0xFF3525CD),
                    onChanged: _notificationsEnabled
                        ? (val) {
                            setModalState(() => _taskDeadlines = val);
                            setState(() => _taskDeadlines = val);
                            _settingsService.updateSettings(taskDeadlines: val);
                            NotificationService.instance.syncNotificationsWithDatabase();
                          }
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAppearanceDialog() {
    final currentMode = ThemeController.instance.themeMode;

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF151D2E) : Colors.white,
          title: const Text('Appearance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('System Default'),
                subtitle: const Text('Match device settings'),
                value: ThemeMode.system,
                groupValue: currentMode,
                activeColor: const Color(0xFF3525CD),
                onChanged: (val) {
                  if (val != null) {
                    ThemeController.instance.setThemeMode(val);
                    _settingsService.updateSettings(theme: 'system');
                    Navigator.pop(ctx);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light Mode'),
                value: ThemeMode.light,
                groupValue: currentMode,
                activeColor: const Color(0xFF3525CD),
                onChanged: (val) {
                  if (val != null) {
                    ThemeController.instance.setThemeMode(val);
                    _settingsService.updateSettings(theme: 'light');
                    Navigator.pop(ctx);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark Mode'),
                value: ThemeMode.dark,
                groupValue: currentMode,
                activeColor: const Color(0xFF3525CD),
                onChanged: (val) {
                  if (val != null) {
                    ThemeController.instance.setThemeMode(val);
                    _settingsService.updateSettings(theme: 'dark');
                    Navigator.pop(ctx);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog() {
    final currentLang = LocaleController.instance.locale.languageCode;

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF151D2E) : Colors.white,
          title: const Text('Language / اللغة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('English'),
                subtitle: const Text('Left-to-right (LTR)'),
                value: 'en',
                groupValue: currentLang,
                activeColor: const Color(0xFF3525CD),
                onChanged: (val) {
                  if (val != null) {
                    LocaleController.instance.setLocale(const Locale('en'));
                    _settingsService.updateSettings(language: 'en');
                    Navigator.pop(ctx);
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('العربية'),
                subtitle: const Text('من اليمين إلى اليسار (RTL)'),
                value: 'ar',
                groupValue: currentLang,
                activeColor: const Color(0xFF3525CD),
                onChanged: (val) {
                  if (val != null) {
                    LocaleController.instance.setLocale(const Locale('ar'));
                    _settingsService.updateSettings(language: 'ar');
                    Navigator.pop(ctx);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentThemeName = switch (ThemeController.instance.themeMode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };
    final currentLangName = LocaleController.instance.locale.languageCode == 'ar' ? 'العربية' : 'English';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const HomeHeader(),
              const SizedBox(height: 25),

              // Profile Avatar with Edit Button
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final changed = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AccountSettingsScreen()),
                        );
                        if (changed == true) _loadUser();
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/study_flow_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, error, stackTrace) {
                              return const CircleAvatar(
                                backgroundColor: Color(0xFF3525CD),
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEECFE),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF151D2E) : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: Color(0xFF3525CD),
                          ),
                          onPressed: () async {
                            final changed = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AccountSettingsScreen()),
                            );
                            if (changed == true) _loadUser();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // User Name
              Text(
                _userName,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),

              // Email
              if (_userEmail.isNotEmpty)
                Text(
                  _userEmail,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              const SizedBox(height: 14),

              // Major Pill Badge (clickable to edit)
              GestureDetector(
                onTap: () async {
                  final changed = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AccountSettingsScreen()),
                  );
                  if (changed == true) _loadUser();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEECFE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.school_outlined,
                        size: 18,
                        color: Color(0xFF3525CD),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _userMajor.isNotEmpty ? _userMajor : 'Set Major',
                        style: const TextStyle(
                          color: Color(0xFF3525CD),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.edit,
                        size: 14,
                        color: Color(0xFF3525CD),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Subscription Plan Card (Free vs Pro)
              _buildPlanCard(context, isDark, RevenueCatService.instance.isPro),
              const SizedBox(height: 20),

              // Settings Box Container
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF151D2E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ProfileOptionTile(
                      icon: Icons.workspace_premium_outlined,
                      title: "Subscription",
                      subtitle: switch (RevenueCatService.instance.subscriptionStatus) {
                        ProSubscriptionStatus.trial =>
                          "StudyFlow Pro (Free Trial Active)",
                        ProSubscriptionStatus.cancelledActive =>
                          "StudyFlow Pro (Cancelled - Active until ${RevenueCatService.instance.formattedExpirationDate ?? 'end of period'})",
                        ProSubscriptionStatus.activePaid =>
                          "StudyFlow Pro (Active)",
                        ProSubscriptionStatus.free =>
                          "Free Plan - Upgrade Available",
                      },
                      onTap: () {
                        if (RevenueCatService.instance.isPro) {
                          RevenueCatService.instance.presentCustomerCenter();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PremiumScreen()),
                          );
                        }
                      },
                    ),
                    ProfileOptionTile(
                      icon: Icons.person_outline,
                      title: "Edit Profile",
                      subtitle: "Change username, major & password",
                      onTap: () async {
                        final changed = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AccountSettingsScreen()),
                        );
                        if (changed == true) _loadUser();
                      },
                    ),
                    ProfileOptionTile(
                      icon: Icons.tune_outlined,
                      title: "Study Preferences",
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const StudyPreferencesScreen(),
                          ),
                        );
                      },
                    ),
                    ProfileOptionTile(
                      icon: Icons.access_time_outlined,
                      title: "Availability",
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AvailabilitySettingsScreen(),
                          ),
                        );
                      },
                    ),
                    ProfileOptionTile(
                      icon: Icons.notifications_none_outlined,
                      title: "Notifications",
                      subtitle: _notificationsEnabled ? "Enabled" : "Disabled",
                      onTap: _showNotificationSettingsModal,
                    ),
                    ProfileOptionTile(
                      icon: Icons.language_outlined,
                      title: "Language",
                      subtitle: currentLangName,
                      onTap: _showLanguageDialog,
                    ),
                    ProfileOptionTile(
                      icon: Icons.palette_outlined,
                      title: "Appearance",
                      subtitle: currentThemeName,
                      onTap: _showAppearanceDialog,
                    ),
                    ProfileOptionTile(
                      icon: Icons.shield_outlined,
                      title: "Security & Verification",
                      showDivider: false,
                      onTap: () async {
                        final changed = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AccountSettingsScreen()),
                        );
                        if (changed == true) _loadUser();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDE8E8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: isDark ? const Color(0xFF151D2E) : Colors.white,
                        title: const Text("Logout"),
                        content: const Text("Are you sure you want to log out?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _handleLogout();
                            },
                            child: const Text(
                              "Logout",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout,
                        color: Color(0xFFDC2626),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Logout",
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, bool isDark, bool isPro) {
    if (isPro) {
      final status = RevenueCatService.instance.subscriptionStatus;
      final exp = RevenueCatService.instance.formattedExpirationDate;

      final String badgeText;
      final Color badgeColor;
      final String statusSubtext;

      switch (status) {
        case ProSubscriptionStatus.trial:
          badgeText = 'TRIAL';
          badgeColor = const Color(0xFF10B981);
          statusSubtext = exp != null ? 'Free Trial • Renews $exp' : 'Free Trial Active • Manage >';
          break;
        case ProSubscriptionStatus.cancelledActive:
          badgeText = 'CANCELLED';
          badgeColor = const Color(0xFFF59E0B);
          statusSubtext = exp != null ? 'Active until $exp (Cancelled)' : 'Access Active (Will not renew)';
          break;
        case ProSubscriptionStatus.activePaid:
        default:
          badgeText = 'PRO';
          badgeColor = const Color(0xFF10B981);
          statusSubtext = exp != null ? 'Renews $exp • Manage >' : 'Manage Subscription >';
          break;
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151D2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                status == ProSubscriptionStatus.cancelledActive
                    ? Icons.access_time_filled_rounded
                    : Icons.verified_rounded,
                color: badgeColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Plan: StudyFlow Pro',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF111827),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () => RevenueCatService.instance.presentCustomerCenter(),
                    child: Text(
                      statusSubtext,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF818CF8) : const Color(0xFF3525CD),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              color: const Color(0xFF3525CD),
              tooltip: 'Manage Subscription',
              onPressed: () => RevenueCatService.instance.presentCustomerCenter(),
            ),
          ],
        ),
      );
    }

    // Free User Card
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PremiumScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3525CD), Color(0xFF5B21B6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3525CD).withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan: Free',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Upgrade to StudyFlow Pro >',
                    style: TextStyle(
                      color: Color(0xFFE0E7FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
