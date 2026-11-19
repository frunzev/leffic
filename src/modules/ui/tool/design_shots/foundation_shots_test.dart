import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/button_look.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_field.dart';
import 'package:leffic/shared/design/design_modal.dart';
import 'package:leffic/shared/design/design_text_field.dart';
import 'package:leffic/shared/design/hint_tip.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';
import 'package:leffic/shared/design/state_block.dart';
import 'package:leffic/shared/navigation/routes.dart';
import 'package:leffic/shared/widgets/app_shell.dart';
import 'package:leffic/shared/widgets/ask_panel_scope.dart';

import 'foundation_gallery.dart';
import 'shot_support.dart';

void _press() {}

Widget _emptyHome() {
  return const AppShell(
    selectedRoute: Routes.folder,
    body: Align(
      alignment: Alignment.topCenter,
      child: StateBlock(
        icon: DesignIcons.folderOpen,
        title: 'Nothing here yet',
        text:
            'Import a file, a link or a topic and Leffic will generate '
            'flashcards, a note and a test from it.',
        action: DesignButton(
          label: 'Import',
          icon: DesignIcons.aiImport,
          variant: ButtonVariant.primary,
          size: ButtonSize.large,
          onPressed: _press,
        ),
      ),
    ),
  );
}

Widget _newFolderModal(BuildContext context) {
  return DesignModal(
    title: 'Create a folder',
    description: 'Folders keep related study units together.',
    body: DesignField(
      label: 'Folder name',
      input: DesignTextField(
        controller: TextEditingController(),
        placeholder: 'e.g. Neuroscience',
        initialFocus: InitialFocus.focused,
      ),
    ),
    actions: const [
      DesignButton(label: 'Cancel', onPressed: _press),
      DesignButton(
        label: 'Create',
        variant: ButtonVariant.primary,
        onPressed: null,
      ),
    ],
  );
}

Future<AskPanelController> _pumpShot(
  WidgetTester tester,
  Brightness brightness,
  Widget home,
) async {
  final askPanel = AskPanelController();

  await pumpShotApp(
    tester,
    brightness: brightness,
    askPanel: askPanel,
    panel: surfacePanelFor(brightness),
    home: home,
  );
  await tester.pump();

  return askPanel;
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('foundation controls in ${brightness.name}', (tester) async {
      await _pumpShot(tester, brightness, const FoundationGallery());

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);

      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(HintTipButton)));
      await saveShot(tester, 'foundation-controls', brightness);
      await mouse.removePointer();
      releaseDesktopWindow();
    });

    testWidgets('foundation empty home in ${brightness.name}', (tester) async {
      await _pumpShot(tester, brightness, _emptyHome());
      await saveShot(tester, 'foundation-home-empty', brightness);
      releaseDesktopWindow();
    });

    testWidgets('foundation profile menu in ${brightness.name}', (
      tester,
    ) async {
      await _pumpShot(tester, brightness, _emptyHome());
      await tester.tap(find.text('Profile'));
      await saveShot(tester, 'foundation-profile-menu', brightness);
      releaseDesktopWindow();
    });

    testWidgets('foundation new folder dialog in ${brightness.name}', (
      tester,
    ) async {
      await _pumpShot(tester, brightness, _emptyHome());

      final page = tester.element(find.byType(AppShell));

      showDesignModal<void>(context: page, builder: _newFolderModal).ignore();
      await saveShot(tester, 'foundation-new-folder-dialog', brightness);
      releaseDesktopWindow();
    });

    testWidgets('foundation ask panel in ${brightness.name}', (tester) async {
      final askPanel = await _pumpShot(tester, brightness, _emptyHome());

      askPanel.open();
      await saveShot(tester, 'foundation-ask-slot', brightness);
      releaseDesktopWindow();
    });
  }
}
