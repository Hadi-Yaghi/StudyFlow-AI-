import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/task_model.dart';

class TaskService {
  final ApiClient _apiClient = ApiClient();

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
          'title': title,
          'description': description,
          'type': type,
          'priority': priority,
          'dueDate': dueDate,
          'estimatedHours': estimatedHours,
          'courseId': courseId,
        },
      );

      return TaskModel.fromJson(response.data);
    } on DioException catch (e) {
      // Optimistic model fallback
      return TaskModel(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        description: description,
        type: type,
        priority: priority,
        dueDate: dueDate,
        estimatedHours: estimatedHours,
        completedHours: 0,
        status: 'TODO',
        courseId: courseId,
      );
    }
  }
}
