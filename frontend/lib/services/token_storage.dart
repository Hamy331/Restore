import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _legacyTokenKey = 'jwt_token';
  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() async =>
      await _read(_accessTokenKey) ?? await _read(_legacyTokenKey);

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      // Unreadable credentials cannot authenticate; allow a fresh login.
      await clear();
      return null;
    }
  }

  Future<void> writeAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> readRefreshToken() => _read(_refreshTokenKey);

  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    // Web storage creates its encryption key on first write. Parallel first
    // writes can encrypt tokens with different keys and corrupt the session.
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.delete(key: _legacyTokenKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _legacyTokenKey);
  }
}
