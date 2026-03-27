import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  // For Android emulator use 10.0.2.2. For iOS simulator use localhost.
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000',
  );

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<void> login({required String email, required String password}) async {
    final response = await _httpClient.post(
      _uri('/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    _throwIfError(response);
  }

  Future<void> signup({required String email, required String password}) async {
    final response = await _httpClient.post(
      _uri('/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    _throwIfError(response);
  }

  Future<List<Map<String, dynamic>>> fetchDashboardProjects() async {
    final json = await _getJson('/dashboard');
    return _readList(json['projects']);
  }

  Future<List<Map<String, dynamic>>> fetchArtists() async {
    final json = await _getJson('/artists');
    return _readList(json['artists']);
  }

  Future<List<Map<String, dynamic>>> fetchProjects() async {
    final json = await _getJson('/projects');
    return _readList(json['projects']);
  }

  Future<List<Map<String, dynamic>>> fetchMessages() async {
    final json = await _getJson('/messages');
    return _readList(json['conversations']);
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final response = await _httpClient.get(_uri(path));
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
