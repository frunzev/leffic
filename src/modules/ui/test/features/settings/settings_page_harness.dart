import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/settings/settings_page.dart';
import 'package:leffic/shared/session/backend_scope.dart';
import 'package:leffic/shared/settings/app_preferences.dart';
import 'package:leffic/shared/settings/chat_engine_choice.dart';
import 'package:leffic/shared/settings/openai_key_store.dart';

import 'settings_fakes.dart';

const String claudeCodeLocation = '/Users/someone/.local/bin/claude';

Future<Directory> preferencesDirectoryWith(
  ChatEngineChoice storedEngine,
) async {
  final directory = await Directory.systemTemp.createTemp('settings');
  final preferences = AppPreferences(chatEngine: storedEngine);

  await savePreferences(directory, preferences);

  return directory;
}

ChatEngineChoice otherEngine(ChatEngineChoice engine) {
  for (final choice in ChatEngineChoice.values) {
    if (choice != engine) {
      return choice;
    }
  }

  throw StateError('There is only one chat engine');
}

SettingsPage settingsPageWith({
  required Directory preferencesDirectory,
  RecordingKeychain? keychain,
  RecordingRelauncher? relauncher,
}) {
  final runKeychain = keychain ?? RecordingKeychain(0);
  final relaunch = relauncher ?? RecordingRelauncher();

  return SettingsPage(
    key: UniqueKey(),
    relaunchBackend: relaunch.relaunch,
    keyStore: OpenAiKeyStore(runKeychain.run),
    findPreferencesDirectory: () async => preferencesDirectory,
    findClaudeCode: () async => claudeCodeLocation,
    runInstallerCommand: (command, input) async {
      return ProcessResult(0, 0, '', '');
    },
  );
}

Future<void> pumpSettings(
  WidgetTester tester,
  BackendLink link,
  SettingsPage settingsPage,
) async {
  await settleAfterDisk(tester, () async {
    await tester.pumpWidget(
      hostedSettings(link: link, settingsPage: settingsPage),
    );
  });
}

void expectRestartedInPlace(
  RecordingRelauncher relauncher,
  BackendLink link,
) {
  expect(find.byType(SettingsPage), findsOneWidget);
  expect(find.text(startupPlaceholder), findsNothing);
  expect(relauncher.relaunched, [link]);
}
