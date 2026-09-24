import 'package:flutter_test/flutter_test.dart';
import 'package:saman_mobile/core/request_id.dart';

void main() {
  test('generates distinct RFC 4122 version 4 request identifiers', () {
    final first = newRequestId();
    final second = newRequestId();
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    expect(first, matches(pattern));
    expect(second, matches(pattern));
    expect(second, isNot(first));
  });
}
