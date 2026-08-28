import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'jwt-token';
  static const String _userIdKey = 'user-id';
  static const String _userNameKey = 'user-name';
  static const String _userEmailKey = 'user-email';

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
  }) async {
    await _storage.write(key: _userIdKey, value: userId.toString());
    await _storage.write(key: _userNameKey, value: name);
    await _storage.write(key: _userEmailKey, value: email);
  }

  static Future<Map<String, String?>> getUserData() async {
    final userId = await _storage.read(key: _userIdKey);
    final name = await _storage.read(key: _userNameKey);
    final email = await _storage.read(key: _userEmailKey);
    return {
      'userId': userId,
      'name': name,
      'email': email,
    };
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userEmailKey);
  }
}