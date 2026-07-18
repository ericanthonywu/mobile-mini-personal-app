import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around FlutterSecureStorage for JWT token management.
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const _tokenKey = 'jwt_token';

  /// Reads the stored JWT token.
  static Future<String?> getToken() => _storage.read(key: _tokenKey);

  /// Stores a JWT token securely in the Keychain.
  static Future<void> setToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  /// Deletes the stored JWT token (logout).
  static Future<void> clearToken() => _storage.delete(key: _tokenKey);

  /// Returns true if a token is stored.
  static Future<bool> hasToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }
}
