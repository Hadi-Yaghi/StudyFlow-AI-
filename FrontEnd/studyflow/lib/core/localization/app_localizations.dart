import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'StudyFlow',
      'login': 'Login',
      'create_account': 'Create Account',
      'continue_with_google': 'Continue with Google',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot password?',
      'dont_have_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',
      'email_verification': 'Email Verification',
      'verify_email': 'Verify Email',
      'verification_code_sent': 'We have sent a 6-digit verification code to',
      'enter_code': 'Enter 6-digit Code',
      'resend_code': 'Resend Code',
      'reset_password': 'Reset Password',
      'send_reset_code': 'Send Reset Code',
      'new_password': 'New Password',
      'confirm_password': 'Confirm Password',
      'current_password': 'Current Password',
      'dashboard': 'Dashboard',
      'schedule': 'Schedule',
      'tasks': 'Tasks',
      'courses': 'Courses',
      'profile': 'Profile',
      'edit_profile': 'Edit Profile',
      'display_name': 'Display Name',
      'major': 'Major',
      'save_changes': 'Save Changes',
      'notifications': 'Notifications',
      'enable_notifications': 'Enable Notifications',
      'study_reminders': 'Study Reminders',
      'task_deadlines': 'Task & Deadline Reminders',
      'language': 'Language',
      'appearance': 'Appearance',
      'theme': 'Theme',
      'system_default': 'System Default',
      'light_mode': 'Light Mode',
      'dark_mode': 'Dark Mode',
      'security': 'Account Security',
      'change_password': 'Change Password',
      'set_password': 'Set Password',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to log out?',
      'cancel': 'Cancel',
      'verified': 'Verified',
      'unverified': 'Unverified',
      'english': 'English',
      'arabic': 'العربية',
    },
    'ar': {
      'app_title': 'ستادي فلو',
      'login': 'تسجيل الدخول',
      'create_account': 'إنشاء حساب جديد',
      'continue_with_google': 'المتابعة باستخدام Google',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'forgot_password': 'نسيت كلمة المرور؟',
      'dont_have_account': 'ليس لديك حساب؟',
      'already_have_account': 'لديك حساب بالفعل؟',
      'email_verification': 'تأكيد البريد الإلكتروني',
      'verify_email': 'تأكيد الحساب',
      'verification_code_sent': 'لقد أرسلنا رمز تأكيد مكون من 6 أرقام إلى',
      'enter_code': 'أدخل الرمز المكون من 6 أرقام',
      'resend_code': 'إعادة إرسال الرمز',
      'reset_password': 'إعادة تعيين كلمة المرور',
      'send_reset_code': 'إرسال رمز التعيين',
      'new_password': 'كلمة المرور الجديدة',
      'confirm_password': 'تأكيد كلمة المرور',
      'current_password': 'كلمة المرور الحالية',
      'dashboard': 'الرئيسية',
      'schedule': 'الجدول',
      'tasks': 'المهام',
      'courses': 'المواد',
      'profile': 'الملف الشخصي',
      'edit_profile': 'تعديل الملف الشخصي',
      'display_name': 'الاسم المستعار',
      'major': 'التخصص الدراسي',
      'save_changes': 'حفظ التغييرات',
      'notifications': 'الإشعارات',
      'enable_notifications': 'تفعيل الإشعارات',
      'study_reminders': 'تذكيرات جلسات المذاكرة',
      'task_deadlines': 'تذكيرات مواعيد المهام',
      'language': 'اللغة',
      'appearance': 'المظهر',
      'theme': 'السمة',
      'system_default': 'تلقائي (حسب النظام)',
      'light_mode': 'الوضع الفاتح',
      'dark_mode': 'الوضع الداكن',
      'security': 'أمان الحساب',
      'change_password': 'تغيير كلمة المرور',
      'set_password': 'تعيين كلمة المرور',
      'logout': 'تسجيل الخروج',
      'logout_confirm': 'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
      'cancel': 'إلغاء',
      'verified': 'موثّق',
      'unverified': 'غير موثّق',
      'english': 'English',
      'arabic': 'العربية',
    },
  };

  String t(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
