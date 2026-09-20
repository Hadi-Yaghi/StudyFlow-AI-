import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/scheduler_result_model.dart';
import '../models/study_session_model.dart';

import 'feature_access_service.dart';

class ScheduleService {
  final ApiClient _apiClient = ApiClient();

  Future<List<StudySessionModel>> getSessionsByDate(DateTime date) async {
    final formattedDate = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    developer.log('Fetching sessions for date: $formattedDate', name: 'ScheduleService');
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.studySessionsUrl,
        queryParameters: {'date': formattedDate},
      );

      if (response.data is List) {
        final sessions = (response.data as List)
            .map((json) => StudySessionModel.fromJson(json))
            .toList();
        developer.log('Received ${sessions.length} sessions for date $formattedDate', name: 'ScheduleService');
        return sessions;
      }
      return [];
    } catch (e) {
      developer.log('Error fetching sessions for date $formattedDate: $e', name: 'ScheduleService');
      return [];
    }
  }

  Future<List<String>> getSessionDates() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.studySessionDatesUrl,
      );

      if (response.data is List) {
        return (response.data as List).map((d) => d.toString()).toList();
      }
      return [];
    } catch (e) {
      developer.log('Error fetching session dates: $e', name: 'ScheduleService');
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
    } catch (e) {
      developer.log('Error fetching task sessions: $e', name: 'ScheduleService');
      return [];
    }
  }

  Future<List<StudySessionModel>> getCourseSessions(int courseId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.getCourseSessionsUrl(courseId),
      );

      if (response.data is List) {
        return (response.data as List)
            .map((json) => StudySessionModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      developer.log('Error fetching course sessions: $e', name: 'ScheduleService');
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
    } catch (e) {
      developer.log('Error updating session status: $e', name: 'ScheduleService');
      return null;
    }
  }

  Future<SchedulerResultModel> generateSchedule() async {
    developer.log('Requesting schedule generation...', name: 'ScheduleService');
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.generateScheduleUrl,
      );
      developer.log('Schedule generation response: status ${response.statusCode}, data: ${response.data}', name: 'ScheduleService');
      if (response.data is Map<String, dynamic>) {
        final result = SchedulerResultModel.fromJson(response.data);
        // Synchronize quota state with FeatureAccessService
        FeatureAccessService.instance.updateFromSchedulerResult(
          remaining: result.remainingFreeGenerations,
          used: result.generatedCount,
        );
        return result;
      }
      return SchedulerResultModel(
        generatedSessions: 0,
        scheduledMinutes: 0,
        unscheduledMinutes: 0,
        sessionDates: [],
      );
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final data = e.response!.data as Map;
        final error = data['error']?.toString();
        if (error == 'SCHEDULE_GENERATION_LIMIT_REACHED') {
          throw Exception('SCHEDULE_GENERATION_LIMIT_REACHED');
        }
      }
      final errorMsg = _extractErrorMessage(e, 'Failed to generate schedule');
      developer.log('DioException generating schedule: $errorMsg', name: 'ScheduleService');
      throw Exception(errorMsg);
    } catch (e) {
      developer.log('Unexpected error generating schedule: $e', name: 'ScheduleService');
      throw Exception(e.toString());
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
