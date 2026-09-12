import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/auth_response_model.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
          major: authData.major,
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
        if (authData.token.isNotEmpty) {
          await TokenStorage.saveToken(authData.token);
          await TokenStorage.saveUserData(
            userId: authData.userId,
            name: authData.name,
            email: authData.email,
            major: authData.major,
          );
        }
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

  Future<AuthResponseModel> loginWithGoogle(String idToken, {String? email, String? name}) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.googleAuthUrl,
        data: {
          'idToken': idToken,
          if (email != null) 'email': email,
          if (name != null) 'name': name,
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
          major: authData.major,
        );
        return authData;
      } else {
        throw Exception(_extractErrorMessage(response.data, 'Google sign-in failed'));
      }
    } on DioException catch (e) {
      final message = _extractErrorMessage(
        e.response?.data,
        e.message ?? 'Google sign-in failed',
      );
      throw Exception(message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Google sign-in failed: ${e.toString()}');
    }
  }

  Future<AuthResponseModel> verifyEmail(String email, String code) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.verifyEmailUrl,
        data: {
          'email': email.trim(),
          'code': code.trim(),
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
          major: authData.major,
        );
        return authData;
      } else {
        throw Exception(_extractErrorMessage(response.data, 'Verification failed'));
      }
    } on DioException catch (e) {
      final message = _extractErrorMessage(
        e.response?.data,
        e.message ?? 'Verification failed',
      );
      throw Exception(message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Verification failed: ${e.toString()}');
    }
  }

  Future<void> resendVerification(String email) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.resendVerificationUrl,
        data: {'email': email.trim()},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(_extractErrorMessage(response.data, 'Failed to resend code'));
      }
    } on DioException catch (e) {
      final message = _extractErrorMessage(
        e.response?.data,
        e.message ?? 'Failed to resend verification code',
      );
      throw Exception(message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to resend code: ${e.toString()}');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.forgotPasswordUrl,
        data: {'email': email.trim()},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(_extractErrorMessage(response.data, 'Failed to request password reset'));
      }
    } on DioException catch (e) {
      final message = _extractErrorMessage(
        e.response?.data,
        e.message ?? 'Failed to send reset code',
      );
      throw Exception(message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to send reset code: ${e.toString()}');
    }
  }

  Future<void> resetPassword(String email, String code, String newPassword) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.resetPasswordUrl,
        data: {
          'email': email.trim(),
          'code': code.trim(),
          'newPassword': newPassword,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(_extractErrorMessage(response.data, 'Failed to reset password'));
      }
    } on DioException catch (e) {
      final message = _extractErrorMessage(
        e.response?.data,
        e.message ?? 'Failed to reset password',
      );
      throw Exception(message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to reset password: ${e.toString()}');
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
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (_) {
      // Best effort Google sign-out
    }
    await TokenStorage.deleteToken();
  }
}

