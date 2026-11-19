import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/import/file_picking.dart';

import '../../support/property.dart';

const MethodChannel _fileSelectorChannel = MethodChannel(
  'plugins.flutter.io/file_selector',
);

void _answerFilePicks(List<String>? chosenPaths) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_fileSelectorChannel, (call) async {
        return chosenPaths;
      });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => _answerFilePicks(null));

  test('pickSourceFileFromDisk property reads the chosen file', () async {
    final examples = <(String, List<int>)>[];
    forAll(
      (random) => (
        '${wordOf(random)}.txt',
        List<int>.generate(random.nextInt(64), (index) => random.nextInt(256)),
      ),
      examples.add,
      runs: 10,
    );
    final directory = await Directory.systemTemp.createTemp('picked');
    addTearDown(() => directory.delete(recursive: true));

    for (final (fileName, content) in examples) {
      final chosen = File('${directory.path}/$fileName');
      await chosen.writeAsBytes(content);
      _answerFilePicks([chosen.path]);

      final picked = await pickSourceFileFromDisk();

      expect(picked!.name, fileName);
      expect(picked.bytes, Uint8List.fromList(content));
    }
  });

  test(
    'pickSourceFileFromDisk property answers nothing when cancelled',
    () async {
      _answerFilePicks(null);

      expect(await pickSourceFileFromDisk(), isNull);
    },
  );
}
