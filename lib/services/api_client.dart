import 'dart:convert';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:http/http.dart' as http;

import 'token_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

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
  static String? _currentUsername;

  /// Override with `--dart-define=API_BASE_URL=http://YOUR_PC_IP:4000` (required on a physical device).
  static const String _envApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String _defaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:4000';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // 10.0.2.2 = host loopback from the Android emulator only.
        return 'http://10.0.2.2:4000';
      case TargetPlatform.iOS:
        return 'http://127.0.0.1:4000';
      default:
        return 'http://127.0.0.1:4000';
    }
  }

  static String get _baseUrl =>
      _envApiBaseUrl.isNotEmpty ? _envApiBaseUrl : _defaultBaseUrl();

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
    ).timeout(const Duration(seconds: 10));
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
    _currentUsername = null;
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

  Future<List<Map<String, dynamic>>> fetchCommissions() async {
    final json = await _getJsonProtected('/commissions');
    return _readList(json['commissions']);
  }

  Future<Map<String, dynamic>> createCommission({
    required String title,
    required String clientName,
    String description = '',
    required double budget,
    String? deadline,
    String specialRequirements = '',
    bool isUrgent = false,
    List<String> referenceImages = const [],
    double totalAmount = 0,
  }) async {
    final response = await _authorizedPost(
      '/commissions',
      body: {
        'title': title,
        'clientName': clientName,
        'description': description,
        'budget': budget,
        'deadline': deadline,
        'specialRequirements': specialRequirements,
        'isUrgent': isUrgent,
        'referenceImages': referenceImages,
        'totalAmount': totalAmount,
      },
    );
    final json = _throwIfErrorAndReadJson(response);
    final commission = json['commission'];
    if (commission is Map) {
      return commission.map((k, v) => MapEntry('$k', v));
    }
    throw ApiException('Unexpected response format.');
  }

  Future<void> updateCommissionStatus(int commissionId, String status) async {
    final response = await _authorizedPut(
      '/commissions/$commissionId/status',
      body: {'status': status},
    );
    _throwIfError(response);
  }

  Future<List<Map<String, dynamic>>> fetchMessages() async {
    final json = await _getJsonProtected('/messages');
    return _readList(json['conversations']);
  }

  Future<List<Map<String, dynamic>>> fetchConversationMessages(int conversationId) async {
    final json = await _getJsonProtected('/messages/$conversationId');
    return _readList(json['messages']);
  }

  Future<Map<String, dynamic>> sendMessage(int conversationId, String content) async {
    final response = await _authorizedPost(
      '/messages/$conversationId',
      body: {'content': content},
    );
    final json = _throwIfErrorAndReadJson(response);
    final message = json['message'];
    if (message is Map) {
      return message.map((k, v) => MapEntry('$k', v));
    }
    throw ApiException('Unexpected response format.');
  }

  Future<Map<String, dynamic>> startConversation(int otherUserId) async {
    final response = await _authorizedPost(
      '/conversations/start',
      body: {'otherUserId': otherUserId},
    );
    final json = _throwIfErrorAndReadJson(response);
    final conversation = json['conversation'];
    if (conversation is Map) {
      return conversation.map((k, v) => MapEntry('$k', v));
    }
    throw ApiException('Unexpected response format.');
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

  Future<List<Map<String, dynamic>>> fetchTaggedPosts(String tag) async {
    final q = Uri.encodeQueryComponent(tag.trim());
    final json = await _getJsonProtected('/posts/tagged?tag=$q');
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

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final q = Uri.encodeQueryComponent(query.trim());
    final json = await _getJsonProtected('/users/search?q=$q');
    return _readList(json['users']);
  }

  Future<Map<String, dynamic>> fetchPublicUser(int userId) async {
    return _getJsonProtected('/users/$userId');
  }

  Future<Map<String, dynamic>> followUser(int userId) async {
    final response = await _authorizedPost('/users/$userId/follow', body: const {});
    return _throwIfErrorAndReadJson(response);
  }

  Future<Map<String, dynamic>> unfollowUser(int userId) async {
    final response = await _authorizedDelete('/users/$userId/follow');
    return _throwIfErrorAndReadJson(response);
  }

  Future<List<Map<String, dynamic>>> fetchUserPosts(int userId) async {
    final json = await _getJsonProtected('/users/$userId/posts');
    return _readList(json['posts']);
  }

  Future<List<Map<String, dynamic>>> fetchFollowers(int userId) async {
    final json = await _getJsonProtected('/users/$userId/followers');
    return _readList(json['users']);
  }

  Future<List<Map<String, dynamic>>> fetchFollowing(int userId) async {
    final json = await _getJsonProtected('/users/$userId/following');
    return _readList(json['users']);
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
    await fetchMe();
    return _currentUserId;
  }

  /// Current user from `/auth/me` (updates cached user id and username).
  Future<Map<String, dynamic>> fetchMe() async {
    final json = await _getJsonProtected('/auth/me');
    _setCurrentUserIdFromMe(json);
    return json;
  }

  /// Username from last [fetchMe] / [getCurrentUserId] / session, or fetches `/auth/me`.
  Future<String?> getCurrentUsername() async {
    if (_currentUsername != null && _currentUsername!.isNotEmpty) {
      return _currentUsername;
    }
    await fetchMe();
    return _currentUsername;
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
      final u = user['username'];
      if (u is String && u.trim().isNotEmpty) {
        _currentUsername = u.trim();
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
        response.statusCode,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Request failed (${response.statusCode})', response.statusCode);
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
    final u = user['username'];
    if (u is String && u.trim().isNotEmpty) {
      _currentUsername = u.trim();
    }
  }
}
