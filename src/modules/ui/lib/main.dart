import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'features/assessment/folder_test_page.dart';
import 'features/assessment/test_page.dart';
import 'features/chat/ask_panel.dart';
import 'features/chat/chat_conversation.dart';
import 'features/files/file_page.dart';
import 'features/flashcards/deck_review_page.dart';
import 'features/flashcards/folder_review_page.dart';
import 'features/folders/folder_page.dart';
import 'features/notes/note_page.dart';
import 'features/settings/libreoffice_installer.dart';
import 'features/settings/libreoffice_release.dart';
import 'features/settings/libreoffice_setup.dart';
import 'features/settings/libreoffice_setup_scope.dart';
import 'features/settings/settings_page.dart';
import 'features/startup/backend_relaunch.dart';
import 'features/startup/startup_page.dart';
import 'shared/design/opaque_page_route.dart';
import 'shared/design/toast_host.dart';
import 'shared/navigation/routes.dart';
import 'shared/session/backend_scope.dart';
import 'shared/settings/openai_key_store.dart';
import 'shared/theme/leffic_theme.dart';
import 'shared/widgets/ask_panel_scope.dart';

void main() {
  runApp(LefficApp(link: BackendLink()));
}

Widget pageFor(RouteSettings settings) {
  final arguments = settings.arguments;

  return switch ((settings.name, arguments)) {
    (Routes.folder, final UnitArguments unit) => FolderPage(arguments: unit),
    (Routes.deckReview, final UnitArguments unit) => DeckReviewPage(
      arguments: unit,
    ),
    (Routes.folderReview, final UnitArguments unit) => FolderReviewPage(
      arguments: unit,
    ),
    (Routes.test, final UnitArguments unit) => TestPage(arguments: unit),
    (Routes.folderTest, final UnitArguments unit) => FolderTestPage(
      arguments: unit,
    ),
    (Routes.note, final UnitArguments unit) => NotePage(arguments: unit),
    (Routes.file, final FileArguments file) => FilePage(arguments: file),
    (Routes.settings, _) => const SettingsPage(
      relaunchBackend: relaunchBackendInPlace,
    ),
    _ => const StartupPage(relaunchBackend: relaunchBackendInPlace),
  };
}

class LefficApp extends StatefulWidget {
  const LefficApp({required this.link, super.key});

  final BackendLink link;

  @override
  State<LefficApp> createState() => _LefficAppState();
}

class _LefficAppState extends State<LefficApp> {
  late final AppLifecycleListener _lifecycle;
  final AskPanelController _askPanel = AskPanelController();
  final ChatConversation _conversation = ChatConversation();
  final TextEditingController _askDraft = TextEditingController();
  final LibreOfficeSetup _libreOfficeSetup = LibreOfficeSetup(
    LibreOfficeInstaller(
      client: http.Client(),
      runCommand: runCommand,
      findDataDirectory: getApplicationSupportDirectory,
      release: libreOfficeRelease,
    ),
  );
  late final Widget _askPanelContent = AskPanel(
    conversation: _conversation,
    draft: _askDraft,
  );

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onExitRequested: _stopBackend);
  }

  Future<AppExitResponse> _stopBackend() async {
    await widget.link.disconnect();

    return AppExitResponse.exit;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _askPanel.dispose();
    _conversation.dispose();
    _askDraft.dispose();
    _libreOfficeSetup.dispose();
    super.dispose();
  }

  Route<void> _routeFor(RouteSettings settings) {
    return OpaquePageRoute(settings: settings, pageFor: pageFor);
  }

  Widget _wrapPages(BuildContext context, Widget? pages) {
    if (pages == null) {
      throw StateError('LefficApp always routes its pages');
    }

    return AskPanelScope(
      controller: _askPanel,
      panel: _askPanelContent,
      child: ToastHost(child: pages),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackendScope(
      link: widget.link,
      child: LibreOfficeSetupScope(
        setup: _libreOfficeSetup,
        child: MaterialApp(
          title: 'Leffic',
          theme: lefficTheme(Brightness.light),
          darkTheme: lefficTheme(Brightness.dark),
          initialRoute: Routes.startup,
          onGenerateRoute: _routeFor,
          builder: _wrapPages,
        ),
      ),
    );
  }
}
