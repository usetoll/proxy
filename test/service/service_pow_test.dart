import 'package:notclawdbot/service/service_pow.dart';
import 'package:test/test.dart';

main() {
  test('verify Pow', () {
    final challenge = '4kYylQ9JZfeSk4+hJTq/6g==';
    final nonce = '0DquAwAAAAAAAAH9AAAACw==';

    final service = ServicePow(16);
    expect(service.verifyPow(challenge: challenge, nonce: nonce), true);
  });
}