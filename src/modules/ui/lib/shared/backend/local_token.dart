import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

const String localUserId = '6b1f9a52-0c3e-4d7a-9f21-3a8e5c4d2b10';
const int _secretByteCount = 32;
const Map<String, String> _tokenHeader = {'alg': 'HS256', 'typ': 'JWT'};

String signLocalToken({required String secret, required String userId}) {
  final encodedHeader = _encodedJson(_tokenHeader);
  final encodedClaims = _encodedJson({'user_id': userId});
  final signingInput = '$encodedHeader.$encodedClaims';
  final signature = Hmac(
    sha256,
    utf8.encode(secret),
  ).convert(utf8.encode(signingInput));

  return '$signingInput.${_unpadded(signature.bytes)}';
}

String newLaunchSecret() {
  final random = Random.secure();
  final secretBytes = List<int>.generate(
    _secretByteCount,
    (_) => random.nextInt(256),
  );

  return _unpadded(secretBytes);
}

String _encodedJson(Map<String, String> json) {
  return _unpadded(utf8.encode(jsonEncode(json)));
}

String _unpadded(List<int> bytes) {
  return base64Url.encode(bytes).replaceAll('=', '');
}
