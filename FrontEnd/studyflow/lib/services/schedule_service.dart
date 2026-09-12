import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/study_session_model.dart';

class ScheduleService {
  final ApiClient _apiClient = ApiClient();

  Future<List<StudySessionModel>> getSessionsByDate(DateTime date) async {
    try {
      final formattedDate = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final response = await _apiClient.dio.get(
        ApiConfig.studySessionsUrl,
        queryParameters: {'date': formattedDate},
      );

      if (response.data is List) {
        return (response.data as List)
            .map((json) => StudySessionModel.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (_) {
      return [];
    }
  }

  Future<List<StudySessionModel>> getTaskSessions(int taskId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.getTaskSessionsUrl(taskId),
      );

      if (response.data is List) {
        return (response.data as List)
            .map((json) => StudySessionModel.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (_) {
      return [];
    }
  }

  Future<StudySessionModel?> updateSessionStatus(
    int sessionId,
    String status, // PLANNED, IN_PROGRESS, COMPLETED, MISSED
    int completedMinutes,
  ) async {
    try {
      final response = await _apiClient.dio.patch(
        ApiConfig.updateSessionStatusUrl(sessionId),
        data: {
          'status': status,
          'completedMinutes': completedMinutes,
        },
      );

      return StudySessionModel.fromJson(response.data);
    } on DioException catch (_) {
      return null;
    }
  }

  Future<bool> generateSchedule() async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.generateScheduleUrl,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      final errorMsg = _extractErrorMessage(e, 'Failed to generate schedule');
      throw Exception(errorMsg);
    }
  }

  String _extractErrorMessage(DioException e, String fallback) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        return data['message'] ?? data['error'] ?? fallback;
      } else if (data is String && data.isNotEmpty) {
        return data;
      }
    }
    return e.message ?? fallback;
  }
}
