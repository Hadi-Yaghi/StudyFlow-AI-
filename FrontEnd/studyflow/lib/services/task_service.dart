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

  Future<TaskModel> updateTask({
    required int taskId,
    required String title,
    required String description,
    required String type, // ASSIGNMENT, EXAM, READING
    required String priority, // HIGH, MEDIUM, LOW
    required String dueDate,
    required int estimatedHours,
    int? completedHours,
    String? status,
    required int courseId,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        ApiConfig.taskItemUrl(taskId),
        data: {
          'title': title.trim(),
          'description': description.trim(),
          'type': type,
          'priority': priority,
          'dueDate': dueDate,
          'estimatedHours': estimatedHours,
          'completedHours': ?completedHours,
          'status': ?status,
          'courseId': courseId,
        },
      );

      return TaskModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to update task'));
    }
  }

  Future<void> deleteTask(int taskId) async {
    try {
      await _apiClient.dio.delete(ApiConfig.taskItemUrl(taskId));
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to delete task'));
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
        final msg = data['message'] ?? data['error'];
        if (msg != null && msg.toString().isNotEmpty) {
          final str = msg.toString();
          if (str.contains('Cannot deserialize') ||
              str.contains('TaskType') ||
              str.contains('Invalid task type') ||
              str.contains('com.') ||
              str.contains('org.') ||
              str.contains('<EOL>')) {
            return "Unable to save the task. Please check the task type and try again.";
          }
          return str;
        }
      } else if (data is String && data.isNotEmpty) {
        if (data.contains('Cannot deserialize') ||
            data.contains('TaskType') ||
            data.contains('Invalid task type') ||
            data.contains('com.') ||
            data.contains('org.')) {
          return "Unable to save the task. Please check the task type and try again.";
        }
        return data;
      }
    }
    return fallback;
  }
}
