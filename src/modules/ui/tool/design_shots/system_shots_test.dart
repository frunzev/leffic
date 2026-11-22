import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/chat/ask_panel.dart';
import 'package:leffic/features/chat/chat_conversation.dart';
import 'package:leffic/features/settings/settings_page.dart';
import 'package:leffic/shared/design/toast.dart';
import 'package:leffic/shared/design/toast_host.dart';
import 'package:leffic/shared/navigation/routes.dart';
import 'package:leffic/shared/session/backend_scope.dart';
import 'package:leffic/shared/settings/openai_key_store.dart';
import 'package:leffic/shared/widgets/app_shell.dart';
import 'package:leffic/shared/widgets/ask_panel_scope.dart';

import 'chat_shot_setup.dart';
import 'folder_shot_data.dart';
import 'shot_support.dart';

const String _designStoredKey = 'sk-proj-design-shot-7Xa2';
const int _keychainItemMissing = 44;
const Duration _diskPatience = Duration(milliseconds: 300);
const List<ToastMessage> _notifications = [
  ToastMessage(
    tone: ToastTone.progress,
    title: 'Generating from action-potentials.pdf',
    detail: 'About a minute. You can keep working.',
  ),
  ToastMessage(tone: ToastTone.success, title: '30 flashcards ready'),
  ToastMessage(
    tone: ToastTone.failure,
    title: "Couldn't generate the note",
    detail: 'The source page timed out.',
  ),
];

class _ShotKeychain {
  const _ShotKeychain(this.storedKey);

  final String? storedKey;

  Future<ProcessResult> run(List<String> command, String? input) async {
    final key = storedKey;

    if (key == null) {
      return ProcessResult(0, _keychainItemMissing, '', '');
    }

    return ProcessResult(0, 0, key, '');
  }
}

Future<void> _keepShotBackend(BackendLink link) async {
  return;
}

SettingsPage _settingsPage({required String? storedKey}) {
  return SettingsPage(
    relaunchBackend: _keepShotBackend,
    keyStore: OpenAiKeyStore(_ShotKeychain(storedKey).run),
    findPreferencesDirectory: () async => Directory.systemTemp,
  );
}

Future<void> _pumpShot(
  WidgetTester tester, {
  required Brightness brightness,
  required Widget home,
  required AskPanelController askPanel,
  required Widget panel,
}) async {
  await pumpShotApp(
    tester,
    brightness: brightness,
    askPanel: askPanel,
    panel: panel,
    home: home,
  );
  await tester.runAsync(() => Future<void>.delayed(_diskPatience));
  await tester.pump();
}

Future<void> _shootChat(
  WidgetTester tester, {
  required Brightness brightness,
  required String slug,
  required ConversationSetUp setUp,
}) async {
  final conversation = ChatConversation();
  final draft = TextEditingController();
  final askPanel = AskPanelController()..open();

  await setUp(tester, conversation);

  await _pumpShot(
    tester,
    brightness: brightness,
    home: shotFolderPage(homeFolderId, filledHome),
    askPanel: askPanel,
    panel: AskPanel(conversation: conversation, draft: draft),
  );
  await saveShot(tester, slug, brightness);
  releaseDesktopWindow();
}

Future<void> _shootSettings(
  WidgetTester tester, {
  required Brightness brightness,
  required String slug,
  required SettingsPage page,
}) async {
  await _pumpShot(
    tester,
    brightness: brightness,
    home: page,
    askPanel: AskPanelController(),
    panel: const SizedBox.shrink(),
  );
  await saveShot(tester, slug, brightness);
  releaseDesktopWindow();
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('chatbot in ${brightness.name}', (tester) async {
      await _shootChat(
        tester,
        brightness: brightness,
        slug: 'chatbot',
        setUp: askAnswered,
      );
    });

    testWidgets('chatbot empty in ${brightness.name}', (tester) async {
      await _shootChat(
        tester,
        brightness: brightness,
        slug: 'chatbot-empty',
        setUp: askNothing,
      );
    });

    testWidgets('chatbot sending in ${brightness.name}', (tester) async {
      await _shootChat(
        tester,
        brightness: brightness,
        slug: 'chatbot-sending',
        setUp: askPending,
      );
    });

    testWidgets('chatbot error in ${brightness.name}', (tester) async {
      await _shootChat(
        tester,
        brightness: brightness,
        slug: 'chatbot-error',
        setUp: askRefused,
      );
    });

    testWidgets('settings keys in ${brightness.name}', (tester) async {
      await _shootSettings(
        tester,
        brightness: brightness,
        slug: 'settings-keys',
        page: _settingsPage(storedKey: _designStoredKey),
      );
    });

    testWidgets('settings no key in ${brightness.name}', (tester) async {
      await _shootSettings(
        tester,
        brightness: brightness,
        slug: 'settings-keys-empty',
        page: _settingsPage(storedKey: null),
      );
    });

    testWidgets('notifications in ${brightness.name}', (tester) async {
      await _pumpShot(
        tester,
        brightness: brightness,
        home: shotFolderPage(homeFolderId, filledHome),
        askPanel: AskPanelController(),
        panel: const SizedBox.shrink(),
      );

      final host = ToastHost.of(tester.element(find.byType(AppShell)));

      for (final notification in _notifications) {
        host.show(notification);
      }

      await saveShot(tester, 'notifications', brightness);
      releaseDesktopWindow();
    });
  }
}
