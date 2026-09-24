import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'session_store.dart';

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, SessionStore? sessionStore})
    : _client = client ?? http.Client(),
      _sessionStore = sessionStore ?? SecureSessionStore();

  final http.Client _client;
  final SessionStore _sessionStore;
  String? token;
  Future<bool>? _refreshInFlight;

  static String get baseUrl => const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080',
  );

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _authRequest('/api/auth/login', {
      'email': email,
      'password': password,
    });
    await _acceptSession(response);
    return response;
  }

  Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await _authRequest('/api/auth/register', {
      'email': email,
      'password': password,
    });
    await _acceptSession(response);
    return response;
  }

  Future<String?> restoreSession() async {
    if (!await _refreshAccessToken()) return null;
    final refreshToken = await _sessionStore.readRefreshToken();
    if (refreshToken == null) return null;
    // The successful refresh response was already accepted. Decode the access
    // token payload only for display would duplicate auth logic, so ask the
    // authenticated backend for the canonical account email.
    final me = await get('/api/auth/me') as Map<String, dynamic>;
    return me['email'] as String;
  }

  Future<void> logout() async {
    final refreshToken = await _sessionStore.readRefreshToken();
    try {
      if (refreshToken != null) {
        await _sendOnce(
          'POST',
          '/api/auth/logout',
          body: {'refreshToken': refreshToken},
          includeAccessToken: false,
        );
      }
    } finally {
      token = null;
      await _sessionStore.clearRefreshToken();
    }
  }

  Future<dynamic> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final result = await _send('POST', path, body: body, extraHeaders: headers);
    return result as Map<String, dynamic>;
  }

  Future<void> delete(String path) async {
    await _send('DELETE', path);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? extraHeaders,
  }) async {
    var response = await _sendOnce(
      method,
      path,
      body: body,
      extraHeaders: extraHeaders,
    );
    if (response.statusCode == 401 &&
        token != null &&
        await _refreshAccessToken()) {
      response = await _sendOnce(
        method,
        path,
        body: body,
        extraHeaders: extraHeaders,
      );
    }
    return _decode(response);
  }

  Future<http.Response> _sendOnce(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? extraHeaders,
    bool includeAccessToken = true,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (includeAccessToken && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (extraHeaders != null) headers.addAll(extraHeaders);

    final uri = Uri.parse('$baseUrl$path');
    late http.Response response;
    try {
      response = switch (method) {
        'GET' => await _client.get(uri, headers: headers),
        'POST' => await _client.post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        ),
        'DELETE' => await _client.delete(uri, headers: headers),
        _ => throw StateError('Unsupported HTTP method: $method'),
      };
    } on http.ClientException {
      throw const ApiException(
        'Backendसँग connect हुन सकेन। Server चलेको छ जाँच गर्नुहोस्।',
        0,
      );
    }

    return response;
  }

  dynamic _decode(http.Response response) {
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw ApiException(
        message ?? 'Request failed (${response.statusCode})',
        response.statusCode,
      );
    }
    return decoded;
  }

  Future<Map<String, dynamic>> _authRequest(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _sendOnce(
      'POST',
      path,
      body: body,
      includeAccessToken: false,
    );
    return _decode(response) as Map<String, dynamic>;
  }

  Future<void> _acceptSession(Map<String, dynamic> response) async {
    final accessToken = response['token'];
    final refreshToken = response['refreshToken'];
    if (accessToken is! String || refreshToken is! String) {
      throw const ApiException('Backend returned an invalid session', 500);
    }
    await _sessionStore.writeRefreshToken(refreshToken);
    token = accessToken;
  }

  Future<bool> _refreshAccessToken() {
    final active = _refreshInFlight;
    if (active != null) return active;
    final refresh = _performRefresh();
    _refreshInFlight = refresh;
    return refresh.whenComplete(() {
      if (identical(_refreshInFlight, refresh)) _refreshInFlight = null;
    });
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await _sessionStore.readRefreshToken();
    if (refreshToken == null) return false;
    try {
      final response = await _authRequest('/api/auth/refresh', {
        'refreshToken': refreshToken,
      });
      await _acceptSession(response);
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        token = null;
        await _sessionStore.clearRefreshToken();
        return false;
      }
      rethrow;
    }
  }
}
