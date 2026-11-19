import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/folders/folder_loading.dart';
import 'package:leffic/features/folders/folder_models.dart';
import 'package:leffic/shared/navigation/routes.dart';
import 'package:leffic/shared/widgets/app_shell.dart';
import 'package:leffic/shared/widgets/ask_panel_scope.dart';

import 'folder_shot_data.dart';
import 'shot_support.dart';

const String _neuroscienceId = 'neuroscience';
const String _deckMenuLabel = 'More actions for Action potentials — deck';

void _ignorePress() {}

Widget _loadingPage() {
  return const AppShell(
    selectedRoute: Routes.folder,
    body: FolderLoading(
      folderId: homeFolderId,
      folderName: homeFolderName,
      onNewFolder: _ignorePress,
    ),
  );
}

Future<void> _pumpShot(
  WidgetTester tester,
  Brightness brightness,
  Widget home,
) async {
  await pumpShotApp(
    tester,
    brightness: brightness,
    askPanel: AskPanelController(),
    panel: surfacePanelFor(brightness),
    home: home,
  );
  await tester.pump();
}

Future<void> _openDeckMenuEntry(WidgetTester tester, String entry) async {
  await tester.tap(find.bySemanticsLabel(_deckMenuLabel));
  await tester.pump();
  await tester.tap(find.text(entry));
  await tester.pump();
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('folder home in ${brightness.name}', (tester) async {
      await _pumpShot(
        tester,
        brightness,
        shotFolderPage(homeFolderId, filledHome),
      );
      await saveShot(tester, 'home', brightness);
      releaseDesktopWindow();
    });

    testWidgets('folder empty in ${brightness.name}', (tester) async {
      await _pumpShot(
        tester,
        brightness,
        shotFolderPage(_neuroscienceId, emptySubfolder),
      );
      await saveShot(tester, 'home-empty', brightness);
      releaseDesktopWindow();
    });

    testWidgets('folder loading in ${brightness.name}', (tester) async {
      await _pumpShot(tester, brightness, _loadingPage());
      await saveShot(tester, 'home-loading', brightness);
      releaseDesktopWindow();
    });

    testWidgets('folder review menu in ${brightness.name}', (tester) async {
      await _pumpShot(
        tester,
        brightness,
        shotFolderPage(homeFolderId, filledHome),
      );
      await tester.tap(find.text('Review 19 items'));
      await saveShot(tester, 'home-study-menu', brightness);
      releaseDesktopWindow();
    });

    testWidgets('folder unit menu in ${brightness.name}', (tester) async {
      await _pumpShot(
        tester,
        brightness,
        shotFolderPage(homeFolderId, filledHome),
      );
      await tester.tap(find.bySemanticsLabel(_deckMenuLabel));
      await saveShot(tester, 'home-unit-menu', brightness);
      releaseDesktopWindow();
    });

    testWidgets('folder profile menu in ${brightness.name}', (tester) async {
      await _pumpShot(
        tester,
        brightness,
        shotFolderPage(homeFolderId, filledHome),
      );
      await tester.tap(find.text('Profile'));
      await saveShot(tester, 'profile-menu', brightness);
      releaseDesktopWindow();
    });

    testWidgets('folder new folder dialog in ${brightness.name}', (
      tester,
    ) async {
      await _pumpShot(
        tester,
        brightness,
        shotFolderPage(homeFolderId, filledHome),
      );
      await tester.tap(find.text('New folder'));
      await saveShot(tester, 'new-folder-dialog', brightness);
      releaseDesktopWindow();
    });

    for (final (entry, slug) in [
      ('Rename', 'folder-rename-dialog'),
      ('Move to folder', 'folder-move-dialog'),
      ('Delete deck', 'folder-delete-dialog'),
    ]) {
      testWidgets('folder $slug in ${brightness.name}', (tester) async {
        await _pumpShot(
          tester,
          brightness,
          shotFolderPage(homeFolderId, filledHome),
        );
        await _openDeckMenuEntry(tester, entry);
        await saveShot(tester, slug, brightness);
        releaseDesktopWindow();
      });
    }
  }
}
