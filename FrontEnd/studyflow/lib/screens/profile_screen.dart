import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/home_header.dart';
import '../widgets/profile_option_tile.dart';
import 'availability_settings_screen.dart';
import 'login_screen.dart';
import 'study_preferences_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  String _userName = "Hadi";
  String _userEmail = "hadi@example.com";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userData = await _authService.getSavedUser();
    if (mounted) {
      setState(() {
        if (userData['name'] != null && userData['name']!.isNotEmpty) {
          _userName = userData['name']!;
        }
        if (userData['email'] != null && userData['email']!.isNotEmpty) {
          _userEmail = userData['email']!;
        }
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Header matching HomeHeader
              const HomeHeader(),
              const SizedBox(height: 25),

              // Profile Avatar with Edit Button
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
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
                            color: Colors.white,
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
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Edit Profile Photo clicked"),
                                duration: Duration(seconds: 1),
                              ),
                            );
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
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),

              // Email
              Text(
                _userEmail,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 14),

              // Major Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEECFE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 18,
                      color: Color(0xFF3525CD),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Computer Science Major",
                      style: TextStyle(
                        color: Color(0xFF3525CD),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Settings Box Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade200,
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
                      onTap: () {
                        _showOptionMessage(context, "Notifications");
                      },
                    ),
                    ProfileOptionTile(
                      icon: Icons.palette_outlined,
                      title: "Appearance",
                      onTap: () {
                        _showOptionMessage(context, "Appearance");
                      },
                    ),
                    ProfileOptionTile(
                      icon: Icons.shield_outlined,
                      title: "Security",
                      showDivider: false,
                      onTap: () {
                        _showOptionMessage(context, "Security");
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

  void _showOptionMessage(BuildContext context, String optionName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$optionName settings opened"),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
