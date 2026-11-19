import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leffic/features/settings/file_download.dart';
import 'package:leffic/features/settings/libreoffice_setup_error.dart';

import '../../support/property.dart';

const String _address = 'https://download.example.org/image.dmg';

List<List<int>> _chunksOf(Random random) {
  final chunkCount = integerBetween(random, 0, 12);

  return [
    for (var chunk = 0; chunk < chunkCount; chunk++)
      [
        for (var index = 0; index < integerBetween(random, 1, 64); index++)
          random.nextInt(256),
      ],
  ];
}

http.Client _serving(List<List<int>> chunks, int statusCode) {
  return MockClient.streaming((request, body) async {
    return http.StreamedResponse(Stream.fromIterable(chunks), statusCode);
  });
}

Future<File> _destination() async {
  final directory = await Directory.systemTemp.createTemp('download');

  return File('${directory.path}/image.dmg');
}

void main() {
  test('downloadToFile property writes every byte in order', () async {
    for (final chunks in examplesOf(_chunksOf)) {
      final destination = await _destination();
      final reported = <int>[];

      await downloadToFile(
        client: _serving(chunks, HttpStatus.ok),
        address: Uri.parse(_address),
        destination: destination,
        onReceived: reported.add,
      );

      final expected = [for (final chunk in chunks) ...chunk];

      expect(await destination.readAsBytes(), expected);
      expect(reported, hasLength(chunks.length));

      for (var index = 1; index < reported.length; index++) {
        expect(reported[index], greaterThan(reported[index - 1]));
      }

      if (reported.isNotEmpty) {
        expect(reported.last, expected.length);
      }
    }
  });

  test('downloadToFile property refuses any status but OK', () async {
    for (final statusCode in examplesOf(
      (random) => oneOf(random, [301, 403, 404, 500, 503]),
    )) {
      final destination = await _destination();

      await expectLater(
        downloadToFile(
          client: _serving([
            [1, 2, 3],
          ], statusCode),
          address: Uri.parse(_address),
          destination: destination,
          onReceived: (receivedBytes) {},
        ),
        throwsA(
          isA<LibreOfficeSetupError>().having(
            (refusal) => refusal.message,
            'message',
            contains('$statusCode'),
          ),
        ),
      );
      expect(await destination.exists(), isFalse);
    }
  });
}
