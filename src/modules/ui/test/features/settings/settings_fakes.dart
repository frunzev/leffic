import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/settings/libreoffice_setup.dart';
import 'package:leffic/features/settings/libreoffice_setup_scope.dart';
import 'package:leffic/features/settings/settings_page.dart';
import 'package:leffic/shared/navigation/routes.dart';
import 'package:leffic/shared/session/backend_scope.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import 'libreoffice_fakes.dart';

const Duration _diskPatience = Duration(milliseconds: 200);
const String startupPlaceholder = 'startup page';

const int _keychainItemMissing = 44;
const String _findCommand = 'find-generic-password';

class RecordingKeychain {
  RecordingKeychain(this.exitCode, {this.storedKey});

  final int exitCode;
  final String? storedKey;
  final List<List<String>> commands = [];
  final List<String?> inputs = [];

  List<List<String>> get changes {
    return [
      for (final command in commands)
        if (!command.contains(_findCommand)) command,
    ];
  }

  Future<ProcessResult> run(List<String> command, String? input) async {
    commands.add(command);
    inputs.add(input);

    if (!command.contains(_findCommand)) {
      return ProcessResult(0, exitCode, '', 'refused');
    }

    final key = storedKey;

    if (key == null) {
      return ProcessResult(0, _keychainItemMissing, '', '');
    }

    return ProcessResult(0, 0, '$key\n', '');
  }
}

BackendLink connectedLink() {
  final client = FakeBackend({}).client();

  return BackendLink()..value = client;
}

Widget _pageNamed(String? routeName, SettingsPage settingsPage) {
  if (routeName == Routes.settings) {
    return settingsPage;
  }

  return const Text(startupPlaceholder);
}

Widget hostedSettings({
  required BackendLink link,
  required SettingsPage settingsPage,
}) {
  final libreOfficeSetup = ScriptedLibreOfficeSetup(
    const LibreOfficeMissing(),
    outcome: const LibreOfficeInstalled(),
  );

  return BackendScope(
    key: UniqueKey(),
    link: link,
    child: LibreOfficeSetupScope(
      setup: libreOfficeSetup,
      child: MaterialApp(
        builder: withShellScopes,
        initialRoute: Routes.settings,
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => _pageNamed(settings.name, settingsPage),
        ),
      ),
    ),
  );
}

Future<void> settleAfterDisk(
  WidgetTester tester,
  Future<void> Function() touchDisk,
) async {
  await tester.runAsync(() async {
    await touchDisk();
    await Future<void>.delayed(_diskPatience);
  });
  await tester.pumpAndSettle();
}
