import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/course_model.dart';

class CourseService {
  final ApiClient _apiClient = ApiClient();

  Future<List<CourseModel>> getCourses() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.coursesUrl);
      if (response.data is List) {
        return (response.data as List)
            .map((json) => CourseModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to load courses'));
    }
  }

  Future<List<Map<String, dynamic>>> getSemesters() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.semestersUrl);
      if (response.data is List) {
        return (response.data as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<int> getOrCreateSemesterByName(String semesterName) async {
    try {
      final semesters = await getSemesters();
      final existing = semesters.firstWhere(
        (s) => s['name']?.toString().trim().toLowerCase() == semesterName.trim().toLowerCase(),
        orElse: () => {},
      );
      if (existing.isNotEmpty && existing['id'] != null) {
        return existing['id'] as int;
      }
    } catch (_) {}

    // Appropriate term dates fallback
    String startDate = "2026-09-01";
    String endDate = "2026-12-31";
    final lower = semesterName.toLowerCase();
    if (lower.contains("spring")) {
      startDate = "2027-01-15";
      endDate = "2027-05-31";
    } else if (lower.contains("summer")) {
      startDate = "2027-06-01";
      endDate = "2027-08-31";
    }

    return await createSemester(
      name: semesterName,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<int> getOrCreateActiveSemester() async {
    try {
      final semesters = await getSemesters();
      if (semesters.isNotEmpty) {
        final activeSem = semesters.firstWhere(
          (s) => s['active'] == true,
          orElse: () => {},
        );
        if (activeSem.isNotEmpty && activeSem['id'] != null) {
          return activeSem['id'] as int;
        }

        final fallSem = semesters.firstWhere(
          (s) => s['name']?.toString().trim().toLowerCase() == "fall 2026",
          orElse: () => {},
        );
        if (fallSem.isNotEmpty && fallSem['id'] != null) {
          return fallSem['id'] as int;
        }

        return semesters.first['id'] as int;
      }
    } catch (_) {}

    return await createSemester(
      name: "Fall 2026",
      startDate: "2026-09-01",
      endDate: "2026-12-31",
    );
  }

  Future<int> createSemester({
    required String name,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.semestersUrl,
        data: {
          'name': name,
          'startDate': startDate,
          'endDate': endDate,
        },
      );
      return response.data['id'] as int? ?? 1;
    } on DioException catch (e) {
      // If already exists or other error, retrieve existing semester
      try {
        final semesters = await getSemesters();
        final match = semesters.firstWhere(
          (s) => s['name']?.toString().trim().toLowerCase() == name.trim().toLowerCase(),
          orElse: () => {},
        );
        if (match.isNotEmpty && match['id'] != null) {
          return match['id'] as int;
        }
        if (semesters.isNotEmpty) {
          return semesters.first['id'] as int;
        }
      } catch (_) {}
      throw Exception(_extractErrorMessage(e, 'Failed to create semester'));
    }
  }

  Future<CourseModel> createCourse({
    required String name,
    required String code,
    required String instructor,
    required int creditHours,
    required String color,
    int? semesterId,
    String? semesterName,
  }) async {
    try {
      int semId;
      if (semesterId != null) {
        semId = semesterId;
      } else if (semesterName != null && semesterName.trim().isNotEmpty) {
        semId = await getOrCreateSemesterByName(semesterName.trim());
      } else {
        semId = await getOrCreateActiveSemester();
      }

      final response = await _apiClient.dio.post(
        ApiConfig.coursesUrl,
        data: {
          'name': name.trim(),
          'code': code.trim().toUpperCase(),
          'instructor': instructor.trim(),
          'creditHours': creditHours,
          'color': color,
          'semesterId': semId,
        },
      );

      return CourseModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to create course'));
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
