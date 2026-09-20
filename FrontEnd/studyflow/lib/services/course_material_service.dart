import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/course_material_model.dart';

class CourseMaterialService {
  CourseMaterialService._internal();
  static final CourseMaterialService instance = CourseMaterialService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Fetches all materials for a course. Both Free and Pro users can view their course materials.
  Future<List<CourseMaterial>> getMaterials(int courseId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConfig.getCourseMaterialsUrl(courseId),
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => CourseMaterial.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CourseMaterialService] Error fetching materials: $e');
      }
      rethrow;
    }
  }

  /// Uploads a course file. Restricted to StudyFlow Pro users on backend.
  Future<CourseMaterial> uploadMaterial({
    required int courseId,
    required String filePath,
    required String filename,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Selected file does not exist.');
      }

      final url = ApiConfig.getCourseMaterialsUrl(courseId);
      if (kDebugMode) {
        debugPrint('[CourseMaterialService] UPLOAD START url=$url filename=$filename size=${await file.length()}');
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: filename,
        ),
      });

      final response = await _apiClient.dio.post(
        url,
        data: formData,
        onSendProgress: (sent, total) {
          if (sent >= total && kDebugMode) {
            debugPrint('[CourseMaterialService] UPLOAD BODY SENT 100%');
          }
          if (onProgress != null) {
            onProgress(sent, total);
          }
        },
      );

      if (kDebugMode) {
        debugPrint('[CourseMaterialService] UPLOAD RESPONSE status=${response.statusCode}');
        debugPrint('[CourseMaterialService] UPLOAD RESPONSE data=${response.data}');
      }

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        return CourseMaterial.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Unexpected server response: ${response.statusCode}');
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[CourseMaterialService] UPLOAD FAILED status=${e.response?.statusCode}');
        debugPrint('[CourseMaterialService] UPLOAD FAILED data=${e.response?.data}');
      }
      if (e.response?.statusCode == 403) {
        throw Exception('PREMIUM_REQUIRED');
      } else if (e.response?.statusCode == 400) {
        final msg = e.response?.data?['message']?.toString() ?? 'Invalid file';
        throw Exception(msg);
      } else if (e.response?.statusCode == 404) {
        throw Exception('Course not found or access denied.');
      } else if (e.response?.statusCode == 413) {
        throw Exception('File size exceeds server upload limit.');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CourseMaterialService] Error uploading material: $e');
      }
      rethrow;
    }
  }

  /// Deletes a course material.
  Future<void> deleteMaterial(int courseId, int materialId) async {
    try {
      await _apiClient.dio.delete(
        ApiConfig.getCourseMaterialDeleteUrl(courseId, materialId),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CourseMaterialService] Error deleting material: $e');
      }
      rethrow;
    }
  }

  /// Gets the download URL with authentication token for a material.
  String getDownloadUrl(int courseId, int materialId) {
    return ApiConfig.getCourseMaterialDownloadUrl(courseId, materialId);
  }
}
