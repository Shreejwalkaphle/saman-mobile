import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? token;

  static String get baseUrl => const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080',
      );

  Future<Map<String, dynamic>> login(String email, String password) {
    return post('/api/auth/login', body: {'email': email, 'password': password});
  }

  Future<Map<String, dynamic>> register(String email, String password) {
    return post('/api/auth/register', body: {'email': email, 'password': password});
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
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (token != null) headers['Authorization'] = 'Bearer $token';
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
      throw const ApiException('Backendसँग connect हुन सकेन। Server चलेको छ जाँच गर्नुहोस्।', 0);
    }

    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw ApiException(message ?? 'Request failed (${response.statusCode})', response.statusCode);
    }
    return decoded;
  }
}
