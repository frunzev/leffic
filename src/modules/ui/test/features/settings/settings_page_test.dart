import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/settings/masked_api_key.dart';
import 'package:leffic/features/settings/settings_page.dart';
import 'package:leffic/shared/design/segmented_control.dart';
import 'package:leffic/shared/session/backend_scope.dart';
import 'package:leffic/shared/settings/app_preferences.dart';
import 'package:leffic/shared/settings/chat_engine_choice.dart';
import 'package:leffic/shared/settings/openai_key_store.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import 'settings_fakes.dart';

const String _claudeCodeLocation = '/Users/someone/.local/bin/claude';

Future<Directory> _preferencesDirectory(ChatEngineChoice storedEngine) async {
  final directory = await Directory.systemTemp.createTemp('settings');
  final preferences = AppPreferences(chatEngine: storedEngine);

  await savePreferences(directory, preferences);

  return directory;
}

ChatEngineChoice _otherEngine(ChatEngineChoice engine) {
  for (final choice in ChatEngineChoice.values) {
    if (choice != engine) {
      return choice;
    }
  }

  throw StateError('There is only one chat engine');
}

SettingsPage _settingsPage({
  required Directory preferencesDirectory,
  RecordingKeychain? keychain,
}) {
  final runKeychain = keychain ?? RecordingKeychain(0);

  return SettingsPage(
    key: UniqueKey(),
    keyStore: OpenAiKeyStore(runKeychain.run),
    findPreferencesDirectory: () async => preferencesDirectory,
    findClaudeCode: () async => _claudeCodeLocation,
    runInstallerCommand: (command, input) async {
      return ProcessResult(0, 0, '', '');
    },
  );
}

Future<void> _pumpSettings(
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

void _expectBackendRestarted() {
  expect(find.byType(SettingsPage), findsNothing);
  expect(find.text(startupPlaceholder), findsOneWidget);
}

void main() {
  testWidgets('SettingsPage property lists the optional components', (
    tester,
  ) async {
    useDesktopSurface(tester);

    final directory = await tester.runAsync(
      () => _preferencesDirectory(ChatEngineChoice.claudeCode),
    );

    await _pumpSettings(
      tester,
      connectedLink(),
      _settingsPage(preferencesDirectory: directory!),
    );

    expect(find.text('Components'), findsOneWidget);
    expect(find.text('LibreOffice'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(
      find.text('Claude Code found at $_claudeCodeLocation'),
      findsOneWidget,
    );
  });

  testWidgets('SettingsPage property shows the stored chat engine', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final engine in ChatEngineChoice.values) {
      final directory = await tester.runAsync(
        () => _preferencesDirectory(engine),
      );
      final link = connectedLink();

      await _pumpSettings(
        tester,
        link,
        _settingsPage(preferencesDirectory: directory!),
      );

      final selector = tester.widget<SegmentedControl<ChatEngineChoice>>(
        find.byType(SegmentedControl<ChatEngineChoice>),
      );

      expect(selector.selected, engine);
      expect(link.value, isNotNull);
    }
  });

  testWidgets('SettingsPage property saves a new engine and restarts', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final engine in ChatEngineChoice.values) {
      final directory = await tester.runAsync(
        () => _preferencesDirectory(engine),
      );
      final link = connectedLink();
      final chosenEngine = _otherEngine(engine);

      await _pumpSettings(
        tester,
        link,
        _settingsPage(preferencesDirectory: directory!),
      );
      await settleAfterDisk(tester, () async {
        await tester.tap(
          find.descendant(
            of: find.byType(SegmentedControl<ChatEngineChoice>),
            matching: find.text(chosenEngine.label),
          ),
        );
      });

      final stored = await tester.runAsync(() => loadPreferences(directory));

      expect(stored!.chatEngine, chosenEngine);
      _expectBackendRestarted();
    }
  });

  testWidgets('SettingsPage property saves a typed key and restarts', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final directory = await tester.runAsync(
      () => _preferencesDirectory(ChatEngineChoice.openAi),
    );

    for (final key in examplesOf(tokenOf, runs: 4)) {
      final keychain = RecordingKeychain(0);
      final link = connectedLink();

      await _pumpSettings(
        tester,
        link,
        _settingsPage(preferencesDirectory: directory!, keychain: keychain),
      );
      await tester.enterText(find.byType(TextField), key);
      await tester.tap(find.text('Save key'));
      await tester.pumpAndSettle();

      expect(keychain.changes.single, ['/usr/bin/security', '-i']);
      expect(keychain.inputs.last, contains('"$key"'));
      _expectBackendRestarted();
    }
  });

  testWidgets('SettingsPage property keeps running when the key is refused', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final directory = await tester.runAsync(
      () => _preferencesDirectory(ChatEngineChoice.openAi),
    );
    final link = connectedLink();

    await _pumpSettings(
      tester,
      link,
      _settingsPage(
        preferencesDirectory: directory!,
        keychain: RecordingKeychain(1),
      ),
    );
    await tester.enterText(find.byType(TextField), 'sk-refused');
    await tester.tap(find.text('Save key'));
    await tester.pumpAndSettle();

    expect(find.textContaining('The keychain refused to save'), findsOneWidget);
    expect(link.value, isNotNull);
    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('SettingsPage property shows a stored key only masked', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final directory = await tester.runAsync(
      () => _preferencesDirectory(ChatEngineChoice.claudeCode),
    );

    for (final key in examplesOf(
      (random) => tokenOf(random, minimum: 20, maximum: 60),
      runs: 3,
    )) {
      await _pumpSettings(
        tester,
        connectedLink(),
        _settingsPage(
          preferencesDirectory: directory!,
          keychain: RecordingKeychain(0, storedKey: key),
        ),
      );

      expect(find.text(maskApiKey(key)), findsOneWidget);
      expect(find.text(key), findsNothing);
      expect(find.text('Replace'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
      expect(find.text('Save key'), findsNothing);
    }
  });

  testWidgets('SettingsPage property removes the stored key and restarts', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final directory = await tester.runAsync(
      () => _preferencesDirectory(ChatEngineChoice.openAi),
    );
    final keychain = RecordingKeychain(0, storedKey: 'sk-stored-key-1234');

    await _pumpSettings(
      tester,
      connectedLink(),
      _settingsPage(preferencesDirectory: directory!, keychain: keychain),
    );
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(keychain.changes.single, [
      '/usr/bin/security',
      'delete-generic-password',
      '-s',
      'leffic-openai-api-key',
      '-a',
      'leffic',
    ]);
    _expectBackendRestarted();
  });

  testWidgets('SettingsPage property keeps running when removing is refused', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final directory = await tester.runAsync(
      () => _preferencesDirectory(ChatEngineChoice.openAi),
    );
    final link = connectedLink();

    await _pumpSettings(
      tester,
      link,
      _settingsPage(
        preferencesDirectory: directory!,
        keychain: RecordingKeychain(1, storedKey: 'sk-stored-key-1234'),
      ),
    );
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('The keychain refused to remove'),
      findsOneWidget,
    );
    expect(link.value, isNotNull);
    expect(find.byType(SettingsPage), findsOneWidget);
  });
}
