import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:saman_mobile/core/api_client.dart';

void main() {
  test('checkout metadata and bearer token reach the backend request', () async {
    late http.BaseRequest captured;
    final transport = _RecordingClient((request) async {
      captured = request;
      return http.Response(jsonEncode({'id': 'order-1'}), 201);
    });
    final api = ApiClient(client: transport)..token = 'access-token';

    final response = await api.post(
      '/api/orders/checkout',
      headers: {'Idempotency-Key': 'request-id'},
      body: {'deliveryQuoteId': 'quote-id'},
    );

    expect(response['id'], 'order-1');
    expect(captured.headers['authorization'], 'Bearer access-token');
    expect(captured.headers['idempotency-key'], 'request-id');
    expect(captured.headers['content-type'], contains('application/json'));
  });
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
