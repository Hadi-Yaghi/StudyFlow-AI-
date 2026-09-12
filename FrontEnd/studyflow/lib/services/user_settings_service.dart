import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../core/network/api_client.dart';

class UserSettingsService {
  final ApiClient _apiClient = ApiClient();

  Map<String, dynamic> _parseResponseData(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    } else if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    return {};
  }

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.userSettingsUrl);
      final data = _parseResponseData(response.data);
      // Cache settings locally
      final prefs = await SharedPreferences.getInstance();
      if (data.containsKey('notificationsEnabled')) {
        await prefs.setBool('notifications_enabled', data['notificationsEnabled'] == true);
      }
      if (data.containsKey('studyReminders')) {
        await prefs.setBool('study_reminders', data['studyReminders'] == true);
      }
      if (data.containsKey('taskDeadlines')) {
        await prefs.setBool('task_deadlines', data['taskDeadlines'] == true);
      }
      return data;
    } catch (_) {
      // Fallback to local preferences
      final prefs = await SharedPreferences.getInstance();
      return {
        'notificationsEnabled': prefs.getBool('notifications_enabled') ?? true,
        'studyReminders': prefs.getBool('study_reminders') ?? true,
        'taskDeadlines': prefs.getBool('task_deadlines') ?? true,
        'theme': prefs.getString('app_theme_mode') ?? 'system',
        'language': prefs.getString('app_locale_lang') ?? 'en',
      };
    }
  }

  Future<Map<String, dynamic>> updateSettings({
    bool? notificationsEnabled,
    bool? studyReminders,
    bool? taskDeadlines,
    String? theme,
    String? language,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (notificationsEnabled != null) {
      await prefs.setBool('notifications_enabled', notificationsEnabled);
    }
    if (studyReminders != null) {
      await prefs.setBool('study_reminders', studyReminders);
    }
    if (taskDeadlines != null) {
      await prefs.setBool('task_deadlines', taskDeadlines);
    }

    try {
      final response = await _apiClient.dio.put(
        ApiConfig.userSettingsUrl,
        data: {
          if (notificationsEnabled != null) 'notificationsEnabled': notificationsEnabled,
          if (studyReminders != null) 'studyReminders': studyReminders,
          if (taskDeadlines != null) 'taskDeadlines': taskDeadlines,
          if (theme != null) 'theme': theme,
          if (language != null) 'language': language,
        },
      );
      return _parseResponseData(response.data);
    } catch (_) {
      return {
        'notificationsEnabled': notificationsEnabled ?? true,
        'studyReminders': studyReminders ?? true,
        'taskDeadlines': taskDeadlines ?? true,
      };
    }
  }
}
