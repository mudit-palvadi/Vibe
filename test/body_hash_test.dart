import 'package:flutter_test/flutter_test.dart';
import 'package:vibe/core/services/body_hash.dart';

void main() {
  test('the hash of a body is the sha256 of the text', () {
    expect(
      sha256Hex('hello'),
      '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824',
    );
  });

  test('the headers of a body carry the hash', () {
    final headers = bodyHeaders('{"a": 1}');

    expect(headers['Content-Type'], 'application/json');
    expect(headers['x-amz-content-sha256'], sha256Hex('{"a": 1}'));
    expect(headers.containsKey('x-vibe-auth'), isFalse);
  });

  test('the session token comes along when there is one', () {
    final headers = bodyHeaders('{"a": 1}', sessionToken: 'session-1');

    expect(headers['x-vibe-auth'], 'session-1');
  });
}
