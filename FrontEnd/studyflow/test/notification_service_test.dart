import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/services/notification_service.dart';

void main() {
  group('NotificationService Deterministic ID Tests', () {
    late NotificationService notificationService;

    setUp(() {
      notificationService = NotificationService.instance;
    });

    test('Deterministic IDs for sessions are distinct and collision-free', () {
      final reminderId1 = notificationService.getSessionReminderId(10);
      final startId1 = notificationService.getSessionStartId(10);
      final reminderId2 = notificationService.getSessionReminderId(11);
      final startId2 = notificationService.getSessionStartId(11);

      expect(reminderId1, equals(1000020));
      expect(startId1, equals(1000021));
      expect(reminderId2, equals(1000022));
      expect(startId2, equals(1000023));

      // Assert all IDs are strictly distinct
      final ids = {reminderId1, startId1, reminderId2, startId2};
      expect(ids.length, equals(4));
    });

    test('Task deadline IDs and session IDs occupy disjoint integer ranges', () {
      final deadlineId = notificationService.getTaskDeadlineId(10);
      final reminderId = notificationService.getSessionReminderId(10);
      final rescheduledId = notificationService.getRescheduledAlertId(10);
      final missedId = notificationService.getMissedAlertId(10);

      expect(deadlineId, equals(2000010));
      expect(reminderId, equals(1000020));
      expect(rescheduledId, equals(3000010));
      expect(missedId, equals(4000010));

      final allIds = {deadlineId, reminderId, rescheduledId, missedId};
      expect(allIds.length, equals(4));
    });
  });
}
