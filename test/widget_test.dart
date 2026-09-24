import 'package:flutter_test/flutter_test.dart';
import 'package:saman_mobile/app.dart';
import 'package:saman_mobile/core/api_client.dart';
import 'package:saman_mobile/core/session_store.dart';

void main() {
  testWidgets('shows customer authentication entry point', (tester) async {
    await tester.pumpWidget(
      SamanApp(api: ApiClient(sessionStore: _MemorySessionStore())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saman'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('नयाँ customer? Register'), findsOneWidget);
  });
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
