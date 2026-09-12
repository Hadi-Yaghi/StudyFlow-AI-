import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();

  Map<String, dynamic> _parseResponseData(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    } else if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    return {};
  }

  String _extractErrorMessage(dynamic data, String fallback) {
    if (data == null) return fallback;
    if (data is Map) {
      final msg = data['message'] ?? data['error'];
      if (msg != null && msg.toString().isNotEmpty) {
        return msg.toString();
      }
    }
    return fallback;
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.userProfileUrl);
      final data = _parseResponseData(response.data);
      if (data.containsKey('name')) {
        await TokenStorage.updateUserProfile(
          name: data['name'] ?? '',
          major: data['major'],
        );
      }
      return data;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e.response?.data, 'Failed to load profile'));
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? major,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        ApiConfig.userProfileUrl,
        data: {
          'name': name.trim(),
          if (major != null) 'major': major.trim(),
        },
      );

      final data = _parseResponseData(response.data);
      await TokenStorage.updateUserProfile(
        name: data['name'] ?? name.trim(),
        major: data['major'] ?? major,
      );
      return data;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e.response?.data, 'Failed to update profile'));
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> changePassword({
    String? currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        ApiConfig.userPasswordUrl,
        data: {
          if (currentPassword != null && currentPassword.isNotEmpty)
            'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(_extractErrorMessage(response.data, 'Failed to change password'));
      }
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e.response?.data, 'Failed to change password'));
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }
}
