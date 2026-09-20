import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/ai_study_plan_model.dart';

class AiStudyService {
  AiStudyService._internal();
  static final AiStudyService instance = AiStudyService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Requests AI study planning for a course.
  ///
  /// Analyzes uploaded course materials, creates structured study tasks,
  /// runs the deterministic scheduler, and returns the generated plan.
  Future<AiStudyPlan> generatePlanForCourse({
    required int courseId,
    List<int>? materialIds,
    String? targetExamDate,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.getAiPlanUrl(courseId),
        data: {
          'materialIds': materialIds,
          'targetExamDate': targetExamDate,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return AiStudyPlan.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Unexpected server response: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('PREMIUM_REQUIRED');
      }
      final serverMsg = e.response?.data?['message']?.toString();
      if (serverMsg != null && serverMsg.isNotEmpty) {
        if (serverMsg.contains('models/') ||
            serverMsg.contains('gemini') ||
            serverMsg.contains('com.') ||
            serverMsg.contains('org.') ||
            serverMsg.contains('Exception') ||
            serverMsg.contains('<EOL>')) {
          throw Exception("AI study planning is temporarily unavailable. Please try again.");
        }
        throw Exception(serverMsg);
      }
      throw Exception("AI study planning is temporarily unavailable. Please try again.");
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AiStudyService] Error generating AI study plan: $e');
      }
      rethrow;
    }
  }
}
