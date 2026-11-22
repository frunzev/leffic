import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/settings/settings_page.dart';
import 'package:leffic/shared/design/segmented_control.dart';
import 'package:leffic/shared/settings/app_preferences.dart';
import 'package:leffic/shared/settings/chat_engine_choice.dart';
import 'package:leffic/shared/settings/openai_key_store.dart';

import '../features/settings/settings_fakes.dart';
import 'requirement_world.dart';
import 'step_definition.dart';

const String _claudeCodeLocation = '/Users/someone/.local/bin/claude';
const String _saveKey = 'Save key';
const String _preferencesFolderPrefix = 'requirement-settings';

ChatEngineChoice _engineLabelled(String label) {
  for (final engine in ChatEngineChoice.values) {
    if (engine.label == label) {
      return engine;
    }
  }

  throw ArgumentError.value(label, 'label', 'names no chat engine');
}

Future<Directory> _preferencesWith(ChatEngineChoice engine) async {
  final directory = await Directory.systemTemp.createTemp(
    _preferencesFolderPrefix,
  );

  await savePreferences(directory, AppPreferences(chatEngine: engine));

  return directory;
}

SettingsPage _settingsPage(UiWorld world, Directory preferencesDirectory) {
  return SettingsPage(
    relaunchBackend: world.relauncher.relaunch,
    keyStore: OpenAiKeyStore(world.keychain.run),
    findPreferencesDirectory: () async => preferencesDirectory,
    findClaudeCode: () async => _claudeCodeLocation,
    runInstallerCommand: (command, input) async => ProcessResult(0, 0, '', ''),
  );
}

ChatEngineChoice? _selectedEngine(WidgetTester tester) {
  final selector = tester.widget<SegmentedControl<ChatEngineChoice>>(
    find.byType(SegmentedControl<ChatEngineChoice>),
  );

  return selector.selected;
}

Future<void> _openSettingsWith(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final engine = _engineLabelled(values.single);
  final directory = await tester.runAsync(() => _preferencesWith(engine));
  final settingsPage = _settingsPage(world, directory!);

  await settleAfterDisk(tester, () async {
    await tester.pumpWidget(
      hostedSettings(link: world.link, settingsPage: settingsPage),
    );
  });
}

Future<void> _chooseEngine(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final engineOption = find.descendant(
    of: find.byType(SegmentedControl<ChatEngineChoice>),
    matching: find.text(values.single),
  );

  await settleAfterDisk(tester, () async {
    await tester.tap(engineOption);
  });
  await settleAfterDisk(tester, () async {});
}

Future<void> _saveOpenAiKey(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  await tester.enterText(find.byType(TextField), values.single);
  await tester.tap(find.text(_saveKey));
  await tester.pumpAndSettle();
}

Future<void> _checkStillInSettings(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  expect(find.byType(SettingsPage), findsOneWidget);
  expect(find.text(startupPlaceholder), findsNothing);
}

Future<void> _checkChosenEngine(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  expect(_selectedEngine(tester), _engineLabelled(values.single));
}

Future<void> _checkRelaunchedOnce(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  expect(world.relauncher.relaunched, [world.link]);
}

final List<StepDefinition> settingsStepDefinitions = [
  StepDefinition(
    'Given',
    RegExp(r'^Settings has "(.+)" chosen as the engine$'),
    _openSettingsWith,
  ),
  StepDefinition(
    'When',
    RegExp(r'^I choose "(.+)" as the engine in Settings$'),
    _chooseEngine,
  ),
  StepDefinition(
    'When',
    RegExp(r'^I save the OpenAI key "(.+)" in Settings$'),
    _saveOpenAiKey,
  ),
  StepDefinition(
    'Then',
    RegExp(r'^the app still shows Settings$'),
    _checkStillInSettings,
  ),
  StepDefinition(
    'Then',
    RegExp(r'^Settings has "(.+)" chosen as the engine$'),
    _checkChosenEngine,
  ),
  StepDefinition(
    'Then',
    RegExp(r'^the backend was restarted in place once$'),
    _checkRelaunchedOnce,
  ),
];
