import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../shared/backend/backend_process.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/navigation/routes.dart';
import '../../shared/session/backend_scope.dart';
import '../../shared/settings/app_preferences.dart';
import '../../shared/settings/chat_engine_choice.dart';
import '../../shared/settings/openai_key_store.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/load_view.dart';
import 'ai_provider_panel.dart';
import 'chat_engine_row.dart';
import 'claude_code_installer.dart';
import 'claude_code_location.dart';
import 'claude_code_row.dart';
import 'keychain_note.dart';
import 'libreoffice_row.dart';
import 'libreoffice_setup_scope.dart';
import 'openai_key_block.dart';
import 'settings_layout.dart';
import 'settings_panel.dart';

typedef PreferencesDirectoryFinder = Future<Directory> Function();
typedef SettingsSnapshot = ({String? storedKey, AppPreferences preferences});

const String _componentsTitle = 'Components';
const String _componentsText =
    'Optional tools Leffic uses on this Mac. Nothing downloads until you '
    'choose it.';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.relaunchBackend,
    this.keyStore = const OpenAiKeyStore(runCommand),
    this.findPreferencesDirectory = getApplicationSupportDirectory,
    this.findClaudeCode = findInstalledClaudeCode,
    this.runInstallerCommand = runCommand,
    super.key,
  });

  final BackendRelauncher relaunchBackend;
  final OpenAiKeyStore keyStore;
  final PreferencesDirectoryFinder findPreferencesDirectory;
  final ClaudeCodeFinder findClaudeCode;
  final CommandRunner runInstallerCommand;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<SettingsSnapshot> _loadSettings() async {
    final storedKey = await widget.keyStore.readKey();
    final directory = await widget.findPreferencesDirectory();
    final preferences = await loadPreferences(directory);
    return (storedKey: storedKey, preferences: preferences);
  }

  Future<void> _saveKey(String key, VoidCallback reload) async {
    await widget.keyStore.saveKey(key);
    await _restartBackend(reload);
  }

  Future<void> _removeKey(VoidCallback reload) async {
    await widget.keyStore.deleteKey();
    await _restartBackend(reload);
  }

  Future<void> _chooseEngine(
    ChatEngineChoice engine,
    VoidCallback reload,
  ) async {
    final directory = await widget.findPreferencesDirectory();

    await savePreferences(directory, AppPreferences(chatEngine: engine));
    await _restartBackend(reload);
  }

  Future<void> _installClaudeCode() {
    return installClaudeCode(widget.runInstallerCommand);
  }

  Future<void> _restartBackend(VoidCallback reload) async {
    if (!mounted) {
      return;
    }

    final link = BackendScope.linkOf(context);
    final navigator = Navigator.of(context);

    try {
      await widget.relaunchBackend(link);
    } on BackendStartError {
      unawaited(
        navigator.pushNamedAndRemoveUntil(Routes.startup, (route) => false),
      );

      return;
    }

    reload();
  }

  Widget _buildSettings(
    BuildContext context,
    SettingsSnapshot snapshot,
    VoidCallback reload,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spacing.step4,
      children: [
        const KeychainNote(),
        OpenAiKeyBlock(
          storedKey: snapshot.storedKey,
          onSave: (key) => _saveKey(key, reload),
          onRemove: () => _removeKey(reload),
        ),
        ChatEngineRow(
          selected: snapshot.preferences.chatEngine,
          onSelected: (engine) => _chooseEngine(engine, reload),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedRoute: Routes.settings,
      body: SettingsLayout(
        panel: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Spacing.step5,
          children: [
            AiProviderPanel(
              body: LoadView<SettingsSnapshot>(
                load: _loadSettings,
                builder: _buildSettings,
              ),
            ),
            SettingsPanel(
              title: _componentsTitle,
              text: _componentsText,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Spacing.step4,
                children: [
                  LibreOfficeRow(setup: LibreOfficeSetupScope.of(context)),
                  ClaudeCodeRow(
                    findClaudeCode: widget.findClaudeCode,
                    installClaudeCode: _installClaudeCode,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
