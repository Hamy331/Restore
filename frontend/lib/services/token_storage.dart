import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _legacyTokenKey = 'jwt_token';
  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() async {
    return await _storage.read(key: _accessTokenKey) ??
        await _storage.read(key: _legacyTokenKey);
  }

  Future<void> writeAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _legacyTokenKey);
  }
}
