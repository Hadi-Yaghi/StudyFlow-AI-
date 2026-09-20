import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/config/api_config.dart';
import 'package:studyflow/models/task_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TaskModel and API Endpoint Tests', () {
    test('ApiConfig task endpoints format correctly', () {
      expect(ApiConfig.tasksUrl, contains('/api/tasks'));
      expect(ApiConfig.taskItemUrl(42), contains('/api/tasks/42'));
      expect(ApiConfig.getCourseTasksUrl(10), contains('/api/tasks/course/10'));
      expect(ApiConfig.updateTaskStatusUrl(42), contains('/api/tasks/42/status'));
    });

    test('TaskModel parses JSON and serializes accurately', () {
      final json = {
        'id': 101,
        'title': 'Operating Systems Project',
        'description': 'Implement virtual memory manager',
        'type': 'PROJECT',
        'priority': 'HIGH',
        'dueDate': '2026-10-30',
        'estimatedHours': 12,
        'completedHours': 4,
        'status': 'IN_PROGRESS',
        'courseId': 5,
      };

      final task = TaskModel.fromJson(json);

      expect(task.id, 101);
      expect(task.title, 'Operating Systems Project');
      expect(task.description, 'Implement virtual memory manager');
      expect(task.type, 'PROJECT');
      expect(task.priority, 'HIGH');
      expect(task.dueDate, '2026-10-30');
      expect(task.estimatedHours, 12);
      expect(task.completedHours, 4);
      expect(task.status, 'IN_PROGRESS');
      expect(task.courseId, 5);

      final serialized = task.toJson();
      expect(serialized['title'], 'Operating Systems Project');
      expect(serialized['estimatedHours'], 12);
      expect(serialized['courseId'], 5);
    });

    test('TaskModel handles missing/null values with sensible defaults', () {
      final emptyJson = <String, dynamic>{};
      final task = TaskModel.fromJson(emptyJson);

      expect(task.id, 0);
      expect(task.title, '');
      expect(task.type, 'ASSIGNMENT');
      expect(task.priority, 'HIGH');
      expect(task.status, 'TODO');
      expect(task.estimatedHours, 0);
      expect(task.completedHours, 0);
      expect(task.courseId, 0);
    });
  });
}
