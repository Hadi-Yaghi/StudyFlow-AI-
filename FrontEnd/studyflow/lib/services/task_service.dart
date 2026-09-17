import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/task_model.dart';

class TaskService {
  final ApiClient _apiClient = ApiClient();

  Future<List<TaskModel>> getTasks() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.tasksUrl);
      if (response.data is List) {
        return (response.data as List)
            .map((json) => TaskModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to load tasks'));
    }
  }

  Future<List<TaskModel>> getCourseTasks(int courseId) async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.getCourseTasksUrl(courseId));
      if (response.data is List) {
        return (response.data as List)
            .map((json) => TaskModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to load course tasks'));
    }
  }

  Future<TaskModel> updateTaskStatus(int taskId, String status) async {
    try {
      final response = await _apiClient.dio.patch(
        ApiConfig.updateTaskStatusUrl(taskId),
        queryParameters: {'status': status},
      );
      return TaskModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to update task status'));
    }
  }

  Future<TaskModel> createTask({
    required String title,
    required String description,
    required String type, // ASSIGNMENT, EXAM, READING
    required String priority, // HIGH, MEDIUM, LOW
    required String dueDate,
    required int estimatedHours,
    required int courseId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.tasksUrl,
        data: {
          'title': title.trim(),
          'description': description.trim(),
          'type': type,
          'priority': priority,
          'dueDate': dueDate,
          'estimatedHours': estimatedHours,
          'courseId': courseId,
        },
      );

      return TaskModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to create task'));
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
