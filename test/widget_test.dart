import 'package:flutter_test/flutter_test.dart';
import 'package:saman_mobile/app.dart';

void main() {
  testWidgets('shows customer authentication entry point', (tester) async {
    await tester.pumpWidget(const SamanApp());

    expect(find.text('Saman'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('नयाँ customer? Register'), findsOneWidget);
  });
}
