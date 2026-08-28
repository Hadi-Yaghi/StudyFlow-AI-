import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/auth_response_model.dart';

class AuthService {
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
    } else if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          final msg = decoded['message'] ?? decoded['error'];
          if (msg != null && msg.toString().isNotEmpty) {
            return msg.toString();
          }
        }
        return data;
      } catch (_) {
        return data;
      }
    }
    return fallback;
  }

  Future<AuthResponseModel> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.loginUrl,
        data: {
          'email': email.trim(),
          'password': password.trim(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final mapData = _parseResponseData(response.data);
        final authData = AuthResponseModel.fromJson(mapData);
        await TokenStorage.saveToken(authData.token);
        await TokenStorage.saveUserData(
          userId: authData.userId,
          name: authData.name,
          email: authData.email,
        );
        return authData;
      } else {
        throw Exception(_extractErrorMessage(response.data, 'Login failed'));
      }
    } on DioException catch (e) {
      final message = _extractErrorMessage(
        e.response?.data,
        e.message ?? 'Invalid email or password',
      );
      throw Exception(message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<AuthResponseModel> register(String name, String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.registerUrl,
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password.trim(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final mapData = _parseResponseData(response.data);
        final authData = AuthResponseModel.fromJson(mapData);
        await TokenStorage.saveToken(authData.token);
        await TokenStorage.saveUserData(
          userId: authData.userId,
          name: authData.name,
          email: authData.email,
        );
        return authData;
      } else {
        throw Exception(_extractErrorMessage(response.data, 'Registration failed'));
      }
    } on DioException catch (e) {
      final message = _extractErrorMessage(
        e.response?.data,
        e.message ?? 'Registration failed',
      );
      throw Exception(message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await TokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, String?>> getSavedUser() async {
    return await TokenStorage.getUserData();
  }

  Future<void> logout() async {
    await TokenStorage.deleteToken();
  }
}
