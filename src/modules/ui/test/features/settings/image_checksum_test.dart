import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/settings/image_checksum.dart';
import 'package:leffic/features/settings/libreoffice_setup_error.dart';

import '../../support/property.dart';

List<int> _bytesOf(Random random) {
  final length = integerBetween(random, 0, 4096);

  return [for (var index = 0; index < length; index++) random.nextInt(256)];
}

String _withOneDigitChanged(String digest, Random random) {
  final position = random.nextInt(digest.length);
  final original = digest[position];
  final replacement = original == '0' ? '1' : '0';

  return digest.replaceRange(position, position + 1, replacement);
}

Future<File> _fileHolding(List<int> bytes) async {
  final directory = await Directory.systemTemp.createTemp('checksum');
  final file = File('${directory.path}/image.dmg');

  await file.writeAsBytes(bytes);

  return file;
}

void main() {
  test('refuseUnlessSha256Matches property accepts the exact digest', () async {
    for (final bytes in examplesOf(_bytesOf)) {
      final file = await _fileHolding(bytes);
      final digest = sha256.convert(bytes).toString();

      await refuseUnlessSha256Matches(file: file, expectedSha256: digest);
    }
  });

  test('refuseUnlessSha256Matches property refuses any other digest', () async {
    for (final (bytes, digitSeed) in examplesOf(
      (random) => (_bytesOf(random), random.nextInt(1 << 30)),
    )) {
      final file = await _fileHolding(bytes);
      final digest = sha256.convert(bytes).toString();
      final wrongDigest = _withOneDigitChanged(digest, Random(digitSeed));

      await expectLater(
        refuseUnlessSha256Matches(file: file, expectedSha256: wrongDigest),
        throwsA(
          isA<LibreOfficeSetupError>().having(
            (refusal) => refusal.message,
            'message',
            contains('checksum'),
          ),
        ),
      );
    }
  });
}
