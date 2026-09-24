import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:saman_mobile/core/api_client.dart';
import 'package:saman_mobile/core/session_store.dart';

void main() {
  test(
    'checkout metadata and bearer token reach the backend request',
    () async {
      late http.BaseRequest captured;
      final transport = _RecordingClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'id': 'order-1'}), 201);
      });
      final api = ApiClient(
        client: transport,
        sessionStore: _MemorySessionStore(),
      )..token = 'access-token';

      final response = await api.post(
        '/api/orders/checkout',
        headers: {'Idempotency-Key': 'request-id'},
        body: {'deliveryQuoteId': 'quote-id'},
      );

      expect(response['id'], 'order-1');
      expect(captured.headers['authorization'], 'Bearer access-token');
      expect(captured.headers['idempotency-key'], 'request-id');
      expect(captured.headers['content-type'], contains('application/json'));
    },
  );

  test(
    'login keeps access token in memory and refresh token in secure store',
    () async {
      final store = _MemorySessionStore();
      final transport = _RecordingClient(
        (request) async => http.Response(
          jsonEncode({
            'token': 'access-1',
            'refreshToken': 'refresh-1',
            'email': 'customer@saman.test',
          }),
          200,
        ),
      );
      final api = ApiClient(client: transport, sessionStore: store);

      await api.login('customer@saman.test', 'password123');

      expect(api.token, 'access-1');
      expect(store.token, 'refresh-1');
    },
  );

  test(
    '401 rotates refresh token then retries original request exactly once',
    () async {
      final paths = <String>[];
      final store = _MemorySessionStore()..token = 'refresh-1';
      var shopAttempts = 0;
      final transport = _RecordingClient((request) async {
        paths.add(request.url.path);
        if (request.url.path == '/api/auth/refresh') {
          final body = jsonDecode(
            (request as http.Request).body,
          ) as Map<String, dynamic>;
          expect(body['refreshToken'], 'refresh-1');
          return http.Response(
            jsonEncode({
              'token': 'access-2',
              'refreshToken': 'refresh-2',
              'email': 'customer@saman.test',
            }),
            200,
          );
        }
        shopAttempts++;
        if (shopAttempts == 1) {
          expect(request.headers['authorization'], 'Bearer expired-access');
          return http.Response(jsonEncode({'message': 'expired'}), 401);
        }
        expect(request.headers['authorization'], 'Bearer access-2');
        return http.Response(jsonEncode(<dynamic>[]), 200);
      });
      final api = ApiClient(client: transport, sessionStore: store)
        ..token = 'expired-access';

      await api.get('/api/shops');

      expect(paths, ['/api/shops', '/api/auth/refresh', '/api/shops']);
      expect(api.token, 'access-2');
      expect(store.token, 'refresh-2');
    },
  );
}

class _RecordingClient extends http.BaseClient {
  _RecordingClient(this.handler);
  final Future<http.Response> Function(http.BaseRequest request) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

class _MemorySessionStore implements SessionStore {
  String? token;

  @override
  Future<void> clearRefreshToken() async => token = null;

  @override
  Future<String?> readRefreshToken() async => token;

  @override
  Future<void> writeRefreshToken(String value) async => token = value;
}
