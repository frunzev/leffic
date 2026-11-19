import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/settings/openai_key_store.dart';

import '../../support/property.dart';

class RecordingRunner {
  RecordingRunner(this.exitCode, this.output);

  final int exitCode;
  final String output;
  final List<List<String>> commands = [];
  final List<String> inputs = [];

  Future<ProcessResult> run(List<String> command, String? input) async {
    commands.add(command);

    if (input != null) {
      inputs.add(input);
    }

    return ProcessResult(0, exitCode, output, '');
  }
}

void main() {
  test('isStorableApiKey property accepts only key characters', () {
    forAll(tokenOf, (key) {
      expect(isStorableApiKey(key), isTrue);
      expect(isStorableApiKey('$key "'), isFalse);
      expect(isStorableApiKey('$key\n'), isFalse);
    });
    expect(isStorableApiKey(''), isFalse);
  });

  test('readKey property returns the stored key or nothing', () async {
    final keys = <String>[];
    forAll(tokenOf, keys.add, runs: 20);

    for (final key in keys) {
      final found = OpenAiKeyStore(RecordingRunner(0, '$key\n').run);
      final missing = OpenAiKeyStore(RecordingRunner(44, '').run);

      expect(await found.readKey(), key);
      expect(await missing.readKey(), isNull);
    }
  });

  test('saveKey property hands the key to the keychain over stdin', () async {
    final keys = <String>[];
    forAll(tokenOf, keys.add, runs: 20);

    for (final key in keys) {
      final runner = RecordingRunner(0, '');

      await OpenAiKeyStore(runner.run).saveKey(key);

      expect(runner.commands.single, ['/usr/bin/security', '-i']);
      expect(runner.inputs.single, contains('"$key"'));
      expect(runner.commands.single.join(' '), isNot(contains(key)));
    }
  });

  test('saveKey property refuses a key it cannot store safely', () async {
    final runner = RecordingRunner(0, '');

    await expectLater(
      OpenAiKeyStore(runner.run).saveKey('bad "key"'),
      throwsArgumentError,
    );
    expect(runner.commands, isEmpty);
  });

  test('deleteKey property removes the stored key or finds none', () async {
    for (final exitCode in [0, 44]) {
      final runner = RecordingRunner(exitCode, '');

      await OpenAiKeyStore(runner.run).deleteKey();

      _expectDeleteCommand(runner.commands.single);
      expect(runner.inputs, isEmpty);
    }
  });

  test('deleteKey property reports a keychain that refused', () async {
    final refusals = <int>[];
    forAll((random) => integerBetween(random, 1, 255), refusals.add, runs: 20);

    for (final exitCode in refusals) {
      final runner = RecordingRunner(exitCode, '');
      final deleting = OpenAiKeyStore(runner.run).deleteKey();

      if (exitCode == 44) {
        await deleting;
      } else {
        await expectLater(deleting, throwsA(isA<KeychainError>()));
      }

      _expectDeleteCommand(runner.commands.single);
    }
  });

  test('saveKey property reports a keychain that refused', () async {
    final runner = RecordingRunner(1, '');

    await expectLater(
      OpenAiKeyStore(runner.run).saveKey('sk-valid'),
      throwsA(isA<KeychainError>()),
    );
  });
}

void _expectDeleteCommand(List<String> command) {
  expect(command, [
    '/usr/bin/security',
    'delete-generic-password',
    '-s',
    'leffic-openai-api-key',
    '-a',
    'leffic',
  ]);
}
