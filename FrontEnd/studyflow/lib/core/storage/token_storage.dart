import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'jwt-token';
  static const String _userIdKey = 'user-id';
  static const String _userNameKey = 'user-name';
  static const String _userEmailKey = 'user-email';
  static const String _userMajorKey = 'user-major';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> saveUserData({
    required int userId,
    required String name,
    required String email,
    String? major,
  }) async {
    await _storage.write(key: _userIdKey, value: userId.toString());
    await _storage.write(key: _userNameKey, value: name);
    await _storage.write(key: _userEmailKey, value: email);
    if (major != null) {
      await _storage.write(key: _userMajorKey, value: major);
    }
  }

  static Future<void> updateUserProfile({
    required String name,
    String? major,
  }) async {
    await _storage.write(key: _userNameKey, value: name);
    if (major != null) {
      await _storage.write(key: _userMajorKey, value: major);
    }
  }

  static Future<Map<String, String?>> getUserData() async {
    final userId = await _storage.read(key: _userIdKey);
    final name = await _storage.read(key: _userNameKey);
    final email = await _storage.read(key: _userEmailKey);
    final major = await _storage.read(key: _userMajorKey);
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'major': major,
    };
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userEmailKey);
    await _storage.delete(key: _userMajorKey);
  }
}