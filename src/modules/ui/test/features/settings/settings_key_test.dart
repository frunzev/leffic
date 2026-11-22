import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/settings/masked_api_key.dart';
import 'package:leffic/features/settings/settings_page.dart';
import 'package:leffic/shared/settings/chat_engine_choice.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import 'settings_fakes.dart';
import 'settings_page_harness.dart';

void main() {
  testWidgets('SettingsPage property saves a typed key and stays open', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final directory = await tester.runAsync(
      () => preferencesDirectoryWith(ChatEngineChoice.openAi),
    );

    for (final key in examplesOf(tokenOf, runs: 4)) {
      final keychain = RecordingKeychain(0);
      final link = connectedLink();
      final relauncher = RecordingRelauncher();

      await pumpSettings(
        tester,
        link,
        settingsPageWith(
          preferencesDirectory: directory!,
          keychain: keychain,
          relauncher: relauncher,
        ),
      );
      await tester.enterText(find.byType(TextField), key);
      await tester.tap(find.text('Save key'));
      await tester.pumpAndSettle();

      final saveCommand = keychain.changes.single;
      final saveInput = keychain.inputs[keychain.commands.indexOf(saveCommand)];

      expect(saveCommand, ['/usr/bin/security', '-i']);
      expect(saveInput, contains('"$key"'));
      expectRestartedInPlace(relauncher, link);
    }
  });

  testWidgets('SettingsPage property keeps running when the key is refused', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final directory = await tester.runAsync(
      () => preferencesDirectoryWith(ChatEngineChoice.openAi),
    );
    final link = connectedLink();

    await pumpSettings(
      tester,
      link,
      settingsPageWith(
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
      () => preferencesDirectoryWith(ChatEngineChoice.claudeCode),
    );

    for (final key in examplesOf(
      (random) => tokenOf(random, minimum: 20, maximum: 60),
      runs: 3,
    )) {
      await pumpSettings(
        tester,
        connectedLink(),
        settingsPageWith(
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

  testWidgets('SettingsPage property removes the stored key in place', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final directory = await tester.runAsync(
      () => preferencesDirectoryWith(ChatEngineChoice.openAi),
    );
    final keychain = RecordingKeychain(0, storedKey: 'sk-stored-key-1234');
    final link = connectedLink();
    final relauncher = RecordingRelauncher();

    await pumpSettings(
      tester,
      link,
      settingsPageWith(
        preferencesDirectory: directory!,
        keychain: keychain,
        relauncher: relauncher,
      ),
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
    expectRestartedInPlace(relauncher, link);
  });

  testWidgets('SettingsPage property keeps running when removing is refused', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final directory = await tester.runAsync(
      () => preferencesDirectoryWith(ChatEngineChoice.openAi),
    );
    final link = connectedLink();

    await pumpSettings(
      tester,
      link,
      settingsPageWith(
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
