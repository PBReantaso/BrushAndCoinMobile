import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenPair {
  final String accessToken;
  final String refreshToken;

  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
  });
}

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _rememberKey = 'remember_me';
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  Future<void> saveRememberMe(bool value) =>
      _storage.write(key: _rememberKey, value: value ? 'true' : 'false');

  Future<bool> readRememberMe() async =>
      (await _storage.read(key: _rememberKey)) == 'true';

  Future<void> saveTokens(TokenPair pair) async {
    await _storage.write(key: _accessTokenKey, value: pair.accessToken);
    await _storage.write(key: _refreshTokenKey, value: pair.refreshToken);
  }

  Future<TokenPair?> readTokens() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (accessToken == null || refreshToken == null) {
      return null;
    }
    return TokenPair(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _rememberKey);
  }
}
