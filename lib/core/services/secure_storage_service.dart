import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for sensitive data (tokens, session info).
/// Uses platform-specific encrypted storage (Keychain on iOS, EncryptedSharedPreferences on Android).
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Storage Keys
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';
  static const String _lastLoginKey = 'last_login';

  /// Save user role securely
  static Future<void> saveUserRole(String role) async {
    await _storage.write(key: _userRoleKey, value: role);
  }

  /// Get stored user role
  static Future<String?> getUserRole() async {
    return await _storage.read(key: _userRoleKey);
  }

  /// Save user ID securely
  static Future<void> saveUserId(String uid) async {
    await _storage.write(key: _userIdKey, value: uid);
  }

  /// Get stored user ID
  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// Save last login timestamp
  static Future<void> saveLastLogin() async {
    await _storage.write(
      key: _lastLoginKey,
      value: DateTime.now().toIso8601String(),
    );
  }

  /// Clear all stored data (on logout)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
