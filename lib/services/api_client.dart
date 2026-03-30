import 'dart:convert';

import 'package:http/http.dart' as http;
import 'token_storage.dart';

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    TokenStorage? tokenStorage,
  })  : _httpClient = httpClient ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final http.Client _httpClient;
  final TokenStorage _tokenStorage;
  static String? _accessToken;
  static String? _refreshToken;

  // For Android emulator use 10.0.2.2. For iOS simulator use localhost.
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000',
  );

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<void> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final response = await _httpClient.post(
      _uri('/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final json = _throwIfErrorAndReadJson(response);
    await _setSessionFromJson(json, rememberMe: rememberMe);
  }

  Future<void> signup({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final response = await _httpClient.post(
      _uri('/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final json = _throwIfErrorAndReadJson(response);
    await _setSessionFromJson(json, rememberMe: rememberMe);
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    await _tokenStorage.clear();
  }

  Future<bool> tryAutoLogin() async {
    final rememberMe = await _tokenStorage.readRememberMe();
    if (!rememberMe) {
      return false;
    }

    final tokens = await _tokenStorage.readTokens();
    if (tokens == null) {
      return false;
    }
    _accessToken = tokens.accessToken;
    _refreshToken = tokens.refreshToken;

    try {
      await _authorizedGet('/auth/me');
      return true;
    } catch (_) {
      try {
        await _refreshAccessToken();
        await _authorizedGet('/auth/me');
        return true;
      } catch (_) {
        await logout();
        return false;
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchDashboardProjects() async {
    final json = await _getJsonProtected('/dashboard');
    return _readList(json['projects']);
  }

  Future<List<Map<String, dynamic>>> fetchArtists() async {
    final json = await _getJsonProtected('/artists');
    return _readList(json['artists']);
  }

  Future<List<Map<String, dynamic>>> fetchProjects() async {
    final json = await _getJsonProtected('/projects');
    return _readList(json['projects']);
  }

  Future<List<Map<String, dynamic>>> fetchMessages() async {
    final json = await _getJsonProtected('/messages');
    return _readList(json['conversations']);
  }

  Future<Map<String, dynamic>> _getJsonProtected(String path) async {
    final response = await _authorizedGet(path);
    return _throwIfErrorAndReadJson(response);
  }

  Future<http.Response> _authorizedGet(String path) async {
    final token = await _getAccessTokenOrThrow();
    var response = await _httpClient.get(
      _uri(path),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401) {
      await _refreshAccessToken();
      final refreshed = await _getAccessTokenOrThrow();
      response = await _httpClient.get(
        _uri(path),
        headers: {'Authorization': 'Bearer $refreshed'},
      );
    }
    return response;
  }

  Future<String> _getAccessTokenOrThrow() async {
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      return _accessToken!;
    }
    final tokens = await _tokenStorage.readTokens();
    if (tokens != null) {
      _accessToken = tokens.accessToken;
      _refreshToken = tokens.refreshToken;
      return tokens.accessToken;
    }
    throw ApiException('Authentication required.');
  }

  Future<void> _refreshAccessToken() async {
    final refreshToken = _refreshToken ?? (await _tokenStorage.readTokens())?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw ApiException('Session expired. Please log in again.');
    }

    final responseRefresh = await _httpClient.post(
      _uri('/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    final json = _throwIfErrorAndReadJson(responseRefresh);
    final newAccessToken = (json['accessToken'] as String?) ?? '';
    if (newAccessToken.isEmpty) {
      throw ApiException('Session refresh failed.');
    }

    _accessToken = newAccessToken;
    final existing = await _tokenStorage.readTokens();
    if (existing != null) {
      await _tokenStorage.saveTokens(
        TokenPair(accessToken: newAccessToken, refreshToken: existing.refreshToken),
      );
    }
  }

  Future<void> _setSessionFromJson(
    Map<String, dynamic> json, {
    required bool rememberMe,
  }) async {
    final accessToken = (json['accessToken'] as String?) ?? '';
    final refreshToken = (json['refreshToken'] as String?) ?? '';
    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw ApiException('Missing auth tokens from server.');
    }

    _accessToken = accessToken;
    _refreshToken = refreshToken;
    // Always persist current session tokens so new ApiClient instances
    // (different screens) can still access protected endpoints.
    await _tokenStorage.saveTokens(
      TokenPair(accessToken: accessToken, refreshToken: refreshToken),
    );
    await _tokenStorage.saveRememberMe(rememberMe);
  }

  Map<String, dynamic> _throwIfErrorAndReadJson(http.Response response) {
    _throwIfError(response);
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw ApiException('Unexpected response format.');
  }

  List<Map<String, dynamic>> _readList(dynamic value) {
    if (value is! List) {
      throw ApiException('Unexpected response format.');
    }
    return value
        .whereType<Map>()
        .map((entry) => entry.map((k, v) => MapEntry('$k', v)))
        .toList();
  }

  void _throwIfError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    try {
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(
        (jsonBody['message'] as String?) ?? 'Request failed (${response.statusCode})',
      );
    } catch (_) {
      throw ApiException('Request failed (${response.statusCode})');
    }
  }
}
