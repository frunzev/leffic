import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/backend/local_token.dart';

import '../../support/property.dart';

Map<String, Object?> _decodedSegment(String segment) {
  final padded = base64Url.normalize(segment);
  final decoded = jsonDecode(utf8.decode(base64Url.decode(padded)));

  return decoded as Map<String, Object?>;
}

void main() {
  test('signLocalToken property signs claims the backend can verify', () {
    forAll((random) => (tokenOf(random), tokenOf(random)), (example) {
      final (secret, userId) = example;
      final token = signLocalToken(secret: secret, userId: userId);
      final segments = token.split('.');
      final signingInput = '${segments[0]}.${segments[1]}';
      final expectedSignature = base64Url
          .encode(
            Hmac(
              sha256,
              utf8.encode(secret),
            ).convert(utf8.encode(signingInput)).bytes,
          )
          .replaceAll('=', '');

      expect(segments, hasLength(3));
      expect(_decodedSegment(segments[0])['alg'], 'HS256');
      expect(_decodedSegment(segments[1])['user_id'], userId);
      expect(segments[2], expectedSignature);
    });
  });

  test('newLaunchSecret property never repeats and stays url safe', () {
    final secrets = <String>{};

    forAll((random) => newLaunchSecret(), (secret) {
      expect(secret, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
      expect(secrets.add(secret), isTrue);
    });
  });
}
