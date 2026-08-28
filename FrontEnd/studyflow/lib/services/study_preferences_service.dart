import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/study_preferences_model.dart';

class StudyPreferencesService {
  final ApiClient _apiClient = ApiClient();

  Future<StudyPreferencesModel?> getPreferences() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.preferencesUrl);
      if (response.data != null) {
        return StudyPreferencesModel.fromJson(response.data);
      }
      return null;
    } on DioException catch (_) {
      return null;
    }
  }

  Future<StudyPreferencesModel?> savePreferences(StudyPreferencesModel preferences) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.preferencesUrl,
        data: preferences.toJson(),
      );
      return StudyPreferencesModel.fromJson(response.data);
    } on DioException catch (_) {
      return preferences;
    }
  }
}
