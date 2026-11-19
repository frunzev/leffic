import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/assessment/file_progress_memory.dart';
import 'package:leffic/features/assessment/test_position.dart';

import '../../support/property.dart';

typedef _Remembered = (String scopeId, TestPosition position);

_Remembered _generatedRemembered(Random random) {
  return (
    oneOf(random, ['home', 'scope-a', 'scope-b', tokenOf(random)]),
    TestPosition(
      pageNumber: integerBetween(random, 1, 20),
      itemIndex: integerBetween(random, 0, 9),
    ),
  );
}

FileProgressMemory _memoryIn(Directory directory, String scopeId) {
  return FileProgressMemory(
    scopeId: scopeId,
    locateDirectory: () async => directory,
  );
}

Future<Directory> _temporaryDirectory() async {
  final directory = await Directory.systemTemp.createTemp('test-progress');

  addTearDown(() => directory.delete(recursive: true));

  return directory;
}

void main() {
  test(
    'FileProgressMemory.recall property starts with nothing stored',
    () async {
      final directory = await _temporaryDirectory();

      for (final scopeId in examplesOf(tokenOf, runs: 10)) {
        final position = await _memoryIn(directory, scopeId).recall();

        expect(position.pageNumber, TestPosition.start.pageNumber);
        expect(position.itemIndex, TestPosition.start.itemIndex);
      }
    },
  );

  test('FileProgressMemory.remember property is what recall reads', () async {
    final directory = await _temporaryDirectory();
    final latest = <String, TestPosition>{};

    for (final (scopeId, position) in examplesOf(_generatedRemembered)) {
      await _memoryIn(directory, scopeId).remember(position);
      latest[scopeId] = position;

      for (final entry in latest.entries) {
        final recalled = await _memoryIn(directory, entry.key).recall();

        expect(recalled.pageNumber, entry.value.pageNumber);
        expect(recalled.itemIndex, entry.value.itemIndex);
      }
    }
  });

  test(
    'FileProgressMemory.forget property forgets only its own scope',
    () async {
      final directory = await _temporaryDirectory();
      const kept = TestPosition(pageNumber: 3, itemIndex: 4);

      await _memoryIn(directory, 'kept').remember(kept);

      for (final (scopeId, position) in examplesOf(_generatedRemembered)) {
        final memory = _memoryIn(directory, 'forgotten-$scopeId');

        await memory.remember(position);
        await memory.forget();

        final forgotten = await memory.recall();
        final stillKept = await _memoryIn(directory, 'kept').recall();

        expect(forgotten.pageNumber, TestPosition.start.pageNumber);
        expect(forgotten.itemIndex, TestPosition.start.itemIndex);
        expect(stillKept.pageNumber, kept.pageNumber);
        expect(stillKept.itemIndex, kept.itemIndex);
      }
    },
  );

  test('FileProgressMemory.recall property refuses a broken file', () async {
    for (final brokenText in examplesOf(
      (random) => oneOf(random, ['[]', '{"scope": 3}', 'not json']),
      runs: 6,
    )) {
      final directory = await _temporaryDirectory();

      await File('${directory.path}/test-progress.json')
          .writeAsString(brokenText);

      await expectLater(
        _memoryIn(directory, 'scope').recall(),
        throwsFormatException,
      );
    }
  });
}
