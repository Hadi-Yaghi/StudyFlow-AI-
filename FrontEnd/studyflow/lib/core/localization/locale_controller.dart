import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static final LocaleController instance = LocaleController._();
  LocaleController._();

  static const String _prefKey = 'app_locale_lang';
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString(_prefKey);
      if (lang == 'ar') {
        _locale = const Locale('ar');
      } else {
        _locale = const Locale('en');
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale.languageCode == locale.languageCode) return;
    _locale = locale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, locale.languageCode);
    } catch (_) {}
  }
}
