import 'package:flutter/material.dart';
import '../core/storage/token_storage.dart';
import '../services/user_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final UserService _userService = UserService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();

  String _email = '';
  bool _emailVerified = true;
  bool _hasPassword = true;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _suggestedMajors = [
    'Computer Science',
    'Software Engineering',
    'Information Technology',
    'Data Science',
    'Business Administration',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Medicine',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _userService.getProfile();
      setState(() {
        _nameController.text = data['name'] ?? '';
        _majorController.text = data['major'] ?? '';
        _email = data['email'] ?? '';
        _emailVerified = data['emailVerified'] == true;
        _hasPassword = data['hasPassword'] == true;
      });
    } catch (_) {
      final savedUser = await TokenStorage.getUserData();
      setState(() {
        _nameController.text = savedUser['name'] ?? '';
        _majorController.text = savedUser['major'] ?? '';
        _email = savedUser['email'] ?? '';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _userService.updateProfile(
        name: _nameController.text.trim(),
        major: _majorController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showChangePasswordSheet() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final passwordFormKey = GlobalKey<FormState>();
    bool isCurrentHidden = true;
    bool isNewHidden = true;
    bool isConfirmHidden = true;
    bool isChanging = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF151D2E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Form(
                  key: passwordFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _hasPassword ? 'Change Password' : 'Set Password',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_hasPassword) ...[
                        TextFormField(
                          controller: currentPasswordController,
                          obscureText: isCurrentHidden,
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isCurrentHidden ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setSheetState(() {
                                  isCurrentHidden = !isCurrentHidden;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Enter current password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: isNewHidden,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isNewHidden ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setSheetState(() {
                                isNewHidden = !isNewHidden;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.length < 6) {
                            return 'Must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: isConfirmHidden,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isConfirmHidden ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setSheetState(() {
                                isConfirmHidden = !isConfirmHidden;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (val) {
                          if (val != newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: isChanging
                            ? null
                            : () async {
                                if (!passwordFormKey.currentState!.validate()) return;
                                setSheetState(() {
                                  isChanging = true;
                                });

                                try {
                                  await _userService.changePassword(
                                    currentPassword: _hasPassword
                                        ? currentPasswordController.text.trim()
                                        : null,
                                    newPassword: newPasswordController.text.trim(),
                                  );

                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Password updated successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setSheetState(() {
                                    isChanging = false;
                                  });
                                  if (sheetContext.mounted) {
                                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString().replaceAll('Exception: ', '')),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3525CD),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isChanging
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _hasPassword ? 'UPDATE PASSWORD' : 'SET PASSWORD',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Account Settings'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3525CD)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF151D2E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Form(
                      key: _profileFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: const Color(0xFF3525CD).withValues(alpha: 0.12),
                                child: const Icon(
                                  Icons.person,
                                  size: 32,
                                  color: Color(0xFF3525CD),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _nameController.text.isNotEmpty
                                          ? _nameController.text
                                          : 'StudyFlow Student',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          _emailVerified
                                              ? Icons.verified
                                              : Icons.warning_amber_rounded,
                                          size: 16,
                                          color: _emailVerified ? Colors.green : Colors.orange,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _emailVerified ? 'Verified Account' : 'Unverified',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _emailVerified ? Colors.green : Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Display Name / Username',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: _email,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Email (Read-only)',
                              prefixIcon: const Icon(Icons.email_outlined),
                              suffixIcon: const Icon(Icons.lock, size: 18, color: Colors.grey),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _majorController,
                            decoration: InputDecoration(
                              labelText: 'Major / Field of Study',
                              hintText: 'e.g. Computer Science',
                              prefixIcon: const Icon(Icons.school_outlined),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: _suggestedMajors.map((major) {
                              final isSelected = _majorController.text.trim().toLowerCase() == major.toLowerCase();
                              return ActionChip(
                                label: Text(
                                  major,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.grey.shade300 : Colors.black87),
                                  ),
                                ),
                                backgroundColor: isSelected
                                    ? const Color(0xFF3525CD)
                                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFF3525CD) : Colors.transparent,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _majorController.text = major;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isSaving ? null : _handleSaveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3525CD),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'SAVE CHANGES',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Security Section Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF151D2E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Security & Authentication',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _hasPassword
                              ? 'Manage your password and security preferences.'
                              : 'You signed in using Google. You can set a password to log in with email as well.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _showChangePasswordSheet,
                          icon: const Icon(Icons.lock_reset, color: Color(0xFF3525CD)),
                          label: Text(
                            _hasPassword ? 'Change Password' : 'Set Password',
                            style: const TextStyle(
                              color: Color(0xFF3525CD),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: const BorderSide(color: Color(0xFF3525CD)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
