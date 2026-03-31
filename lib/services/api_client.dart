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
  static int? _currentUserId;

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
    _currentUserId = null;
    await _tokenStorage.clear();
  }

  Future<void> deleteAccount({required String password}) async {
    final response = await _authorizedPost(
      '/auth/delete',
      body: {'password': password},
    );
    _throwIfError(response);
    await logout();
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
      final meResponse = await _authorizedGet('/auth/me');
      final meJson = _throwIfErrorAndReadJson(meResponse);
      _setCurrentUserIdFromMe(meJson);
      return true;
    } catch (_) {
      try {
        await _refreshAccessToken();
        final meResponse = await _authorizedGet('/auth/me');
        final meJson = _throwIfErrorAndReadJson(meResponse);
        _setCurrentUserIdFromMe(meJson);
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

  Future<List<Map<String, dynamic>>> fetchEvents() async {
    final json = await _getJsonProtected('/events');
    return _readList(json['events']);
  }

  Future<List<Map<String, dynamic>>> fetchFeedPosts() async {
    final json = await _getJsonProtected('/posts/feed');
    return _readList(json['posts']);
  }

  Future<List<Map<String, dynamic>>> fetchMyPosts() async {
    final json = await _getJsonProtected('/posts/mine');
    return _readList(json['posts']);
  }

  Future<Map<String, dynamic>> createPost({
    required String title,
    required String description,
    required String category,
    required double price,
    required bool isCommissionAvailable,
    required List<String> tags,
    String? imageUrl,
  }) async {
    final response = await _authorizedPost(
      '/posts',
      body: {
        'title': title,
        'description': description,
        'category': category,
        'price': price,
        'isCommissionAvailable': isCommissionAvailable,
        'tags': tags,
        'imageUrl': imageUrl,
      },
    );
    final json = _throwIfErrorAndReadJson(response);
    final post = json['post'];
    if (post is Map) {
      return post.map((k, v) => MapEntry('$k', v));
    }
    throw ApiException('Unexpected response format.');
  }

  Future<void> likePost(int postId) async {
    final response = await _authorizedPost('/posts/$postId/likes', body: const {});
    _throwIfError(response);
  }

  Future<void> unlikePost(int postId) async {
    final response = await _authorizedDelete('/posts/$postId/likes');
    _throwIfError(response);
  }

  Future<void> commentOnPost({
    required int postId,
    required String comment,
  }) async {
    final response = await _authorizedPost(
      '/posts/$postId/comments',
      body: {'comment': comment},
    );
    _throwIfError(response);
  }

  Future<List<Map<String, dynamic>>> fetchPostComments(int postId) async {
    final json = await _getJsonProtected('/posts/$postId/comments');
    return _readList(json['comments']);
  }

  Future<void> updateProfile({required String username}) async {
    final response = await _authorizedPost(
      '/auth/profile',
      body: {'username': username},
    );
    final json = _throwIfErrorAndReadJson(response);
    await _setSessionFromJson(json, rememberMe: true);
  }

  Future<Map<String, dynamic>> createEvent({
    required String title,
    required String category,
    required String eventDate,
    required String eventTime,
    required String venue,
    required String locationText,
    required double? latitude,
    required double? longitude,
    required String description,
    required String additionalInfo,
    required List<Map<String, String>> schedules,
    String? imageUrl,
  }) async {
    final response = await _authorizedPost(
      '/events',
      body: {
        'title': title,
        'category': category,
        'eventDate': eventDate,
        'eventTime': eventTime,
        'venue': venue,
        'locationText': locationText,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'additionalInfo': additionalInfo,
        'imageUrl': imageUrl,
        'schedules': schedules,
      },
    );
    final json = _throwIfErrorAndReadJson(response);
    final event = json['event'];
    if (event is Map) {
      return event.map((k, v) => MapEntry('$k', v));
    }
    throw ApiException('Unexpected response format.');
  }

  Future<Map<String, dynamic>> updateEvent({
    required int eventId,
    required String title,
    required String category,
    required String eventDate,
    required String eventTime,
    required String venue,
    required String locationText,
    required double? latitude,
    required double? longitude,
    required String description,
    required String additionalInfo,
    required List<Map<String, String>> schedules,
    String? imageUrl,
  }) async {
    final response = await _authorizedPut(
      '/events/$eventId',
      body: {
        'title': title,
        'category': category,
        'eventDate': eventDate,
        'eventTime': eventTime,
        'venue': venue,
        'locationText': locationText,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'additionalInfo': additionalInfo,
        'imageUrl': imageUrl,
        'schedules': schedules,
      },
    );
    final json = _throwIfErrorAndReadJson(response);
    final event = json['event'];
    if (event is Map) {
      return event.map((k, v) => MapEntry('$k', v));
    }
    throw ApiException('Unexpected response format.');
  }

  Future<void> deleteEvent(int eventId) async {
    final response = await _authorizedDelete('/events/$eventId');
    _throwIfError(response);
  }

  Future<int?> getCurrentUserId() async {
    if (_currentUserId != null) return _currentUserId;
    final response = await _authorizedGet('/auth/me');
    final json = _throwIfErrorAndReadJson(response);
    _setCurrentUserIdFromMe(json);
    return _currentUserId;
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

  Future<http.Response> _authorizedPost(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final token = await _getAccessTokenOrThrow();
    var response = await _httpClient.post(
      _uri(path),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      await _refreshAccessToken();
      final refreshed = await _getAccessTokenOrThrow();
      response = await _httpClient.post(
        _uri(path),
        headers: {
          'Authorization': 'Bearer $refreshed',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
    }
    return response;
  }

  Future<http.Response> _authorizedPut(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final token = await _getAccessTokenOrThrow();
    var response = await _httpClient.put(
      _uri(path),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      await _refreshAccessToken();
      final refreshed = await _getAccessTokenOrThrow();
      response = await _httpClient.put(
        _uri(path),
        headers: {
          'Authorization': 'Bearer $refreshed',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
    }
    return response;
  }

  Future<http.Response> _authorizedDelete(String path) async {
    final token = await _getAccessTokenOrThrow();
    var response = await _httpClient.delete(
      _uri(path),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401) {
      await _refreshAccessToken();
      final refreshed = await _getAccessTokenOrThrow();
      response = await _httpClient.delete(
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
    final user = json['user'];
    if (user is Map) {
      final id = user['id'];
      if (id is int) {
        _currentUserId = id;
      } else if (id is String) {
        _currentUserId = int.tryParse(id);
      }
    }
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

  void _setCurrentUserIdFromMe(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is! Map) return;
    final id = user['id'];
    if (id is int) {
      _currentUserId = id;
    } else if (id is String) {
      _currentUserId = int.tryParse(id);
    }
  }
}
