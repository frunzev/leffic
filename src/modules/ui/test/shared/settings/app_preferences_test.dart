import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/settings/app_preferences.dart';
import 'package:leffic/shared/settings/chat_engine_choice.dart';

import '../../support/property.dart';

void main() {
  test('decodePreferences property round-trips encodePreferences', () {
    forAll((random) => oneOf(random, ChatEngineChoice.values), (engine) {
      final preferences = AppPreferences(chatEngine: engine);

      expect(
        decodePreferences(encodePreferences(preferences)).chatEngine,
        engine,
      );
    });
  });

  test('decodePreferences property refuses an unknown chat engine', () {
    forAll(wordOf, (unknown) {
      expect(
        () => decodePreferences('{"chat_engine":"x$unknown"}'),
        throwsFormatException,
      );
    });
  });

  test('chatEngineNamed property finds every choice by its setting', () {
    for (final engine in ChatEngineChoice.values) {
      expect(chatEngineNamed(engine.setting), engine);
    }
  });

  test(
    'loadPreferences property reads back what savePreferences wrote',
    () async {
      final directory = await Directory.systemTemp.createTemp('preferences');
      final engines = <ChatEngineChoice>[];
      forAll(
        (random) => oneOf(random, ChatEngineChoice.values),
        engines.add,
        runs: 10,
      );

      for (final engine in engines) {
        await savePreferences(directory, AppPreferences(chatEngine: engine));

        expect((await loadPreferences(directory)).chatEngine, engine);
      }

      await directory.delete(recursive: true);
    },
  );

  test(
    'loadPreferences property starts from Claude Code without a file',
    () async {
      final directory = await Directory.systemTemp.createTemp('preferences');

      expect(
        (await loadPreferences(directory)).chatEngine,
        ChatEngineChoice.claudeCode,
      );

      await directory.delete(recursive: true);
    },
  );
}
