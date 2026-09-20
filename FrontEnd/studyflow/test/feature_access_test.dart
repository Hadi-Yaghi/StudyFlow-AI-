import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/models/ai_study_plan_model.dart';
import 'package:studyflow/models/course_material_model.dart';
import 'package:studyflow/models/scheduler_result_model.dart';
import 'package:studyflow/services/feature_access_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FeatureAccessService Tests', () {
    final access = FeatureAccessService.instance;

    test('Free user has restricted access to premium features', () {
      expect(access.isPro, isFalse);
      expect(access.canUploadCourseFiles, isFalse);
      expect(access.canUseAi, isFalse);
      expect(access.canGenerateWithAi, isFalse);
      expect(FeatureAccessService.freeScheduleGenerationLimit, 3);
    });

    test('Free user can generate schedule within quota limit', () {
      access.updateFromSchedulerResult(remaining: 2, used: 1);
      expect(access.remainingFreeScheduleGenerations, 2);
      expect(access.usedFreeScheduleGenerations, 1);
      expect(access.canGenerateSchedule, isTrue);

      // When quota reaches 0
      access.updateFromSchedulerResult(remaining: 0, used: 3);
      expect(access.remainingFreeScheduleGenerations, 0);
      expect(access.usedFreeScheduleGenerations, 3);
      expect(access.canGenerateSchedule, isFalse);
    });
  });

  group('CourseMaterial Model Tests', () {
    test('CourseMaterial parses JSON correctly and formats file size', () {
      final json = {
        'id': 42,
        'courseId': 101,
        'originalFilename': 'syllabus_algorithms.pdf',
        'mimeType': 'application/pdf',
        'fileSize': 1048576, // 1 MB
        'uploadedAt': '2026-09-19T10:00:00Z',
        'processingStatus': 'PROCESSED',
      };

      final material = CourseMaterial.fromJson(json);

      expect(material.id, 42);
      expect(material.courseId, 101);
      expect(material.originalFilename, 'syllabus_algorithms.pdf');
      expect(material.fileExtension, 'PDF');
      expect(material.formattedFileSize, '1.0 MB');
      expect(material.processingStatus, 'PROCESSED');
    });

    test('CourseMaterial handles various file extensions', () {
      final docx = CourseMaterial(
        id: 1,
        courseId: 1,
        originalFilename: 'lecture_notes.docx',
        mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        fileSize: 2048,
        uploadedAt: DateTime.now(),
        processingStatus: 'PROCESSED',
      );
      expect(docx.fileExtension, 'DOCX');
      expect(docx.formattedFileSize, '2.0 KB');
    });
  });

  group('AiStudyPlan Model Tests', () {
    test('AiStudyPlan and AiTopicRecommendation parse structured JSON', () {
      final json = {
        'courseId': 101,
        'courseName': 'Algorithms',
        'summary': 'Focus on graph algorithms and dynamic programming.',
        'topics': [
          {
            'title': 'Dynamic Programming Memoization',
            'estimatedMinutes': 120,
            'priority': 'HIGH',
            'suggestedDeadline': '2026-09-25',
            'sourceMaterialId': 42,
            'keyConcepts': ['Memoization', 'Optimal Substructure', 'Overlap'],
          },
          {
            'title': 'Shortest Path - Dijkstra',
            'estimatedMinutes': 90,
            'priority': 'MEDIUM',
            'suggestedDeadline': '2026-09-27',
            'sourceMaterialId': 42,
            'keyConcepts': ['PriorityQueue', 'Adjacency List'],
          }
        ],
        'generatedSessionsCount': 4,
        'scheduledMinutes': 210,
        'sessionDates': ['2026-09-20', '2026-09-21'],
        'successful': true,
        'message': 'Successfully generated AI plan',
      };

      final plan = AiStudyPlan.fromJson(json);

      expect(plan.courseId, 101);
      expect(plan.courseName, 'Algorithms');
      expect(plan.successful, isTrue);
      expect(plan.topics.length, 2);
      expect(plan.topics[0].title, 'Dynamic Programming Memoization');
      expect(plan.topics[0].estimatedMinutes, 120);
      expect(plan.topics[0].priority, 'HIGH');
      expect(plan.topics[0].keyConcepts.length, 3);
      expect(plan.generatedSessionsCount, 4);
      expect(plan.scheduledMinutes, 210);
      expect(plan.sessionDates.length, 2);
    });
  });

  group('SchedulerResultModel Quota Fields Tests', () {
    test('SchedulerResultModel parses remainingFreeGenerations and isPro', () {
      final json = {
        'generatedSessions': 5,
        'scheduledMinutes': 250,
        'unscheduledMinutes': 0,
        'sessionDates': ['2026-09-20'],
        'status': 'SUCCESS',
        'remainingFreeGenerations': 2,
        'generatedCount': 1,
        'isPro': false,
      };

      final result = SchedulerResultModel.fromJson(json);

      expect(result.generatedSessions, 5);
      expect(result.remainingFreeGenerations, 2);
      expect(result.generatedCount, 1);
      expect(result.isPro, isFalse);
    });
  });
}
