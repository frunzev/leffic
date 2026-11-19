import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/folders/folder_header.dart';
import 'package:leffic/features/folders/folder_models.dart';
import 'package:leffic/shared/design/button_look.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/icons/design_icon.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';
import 'folder_ancestry.dart';

class _Header {
  final List<String> pressed = [];

  Widget header(List<FolderAncestor> ancestors, String folderName) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 856,
        child: FolderHeader(
          ancestors: ancestors,
          folderName: folderName,
          actions: [
            NewFolderButton(onPressed: () => pressed.add('new folder')),
            ImportButton(onPressed: () => pressed.add('import')),
          ],
        ),
      ),
    );
  }
}

typedef _HeaderExample = ({
  List<FolderAncestor> ancestors,
  String folderName,
  Brightness brightness,
});

List<_HeaderExample> _headerExamples(int runs) {
  return examplesOf(
    (random) => (
      ancestors: generatedAncestors(random),
      folderName: 'Folder ${wordOf(random, maximum: 6)}',
      brightness: oneOf(random, Brightness.values),
    ),
    runs: runs,
  );
}

Finder _title(String folderName) {
  return find.text(folderName).last;
}

TextStyle _titleStyle(WidgetTester tester, String folderName) {
  final paragraph = tester.widget<RichText>(
    find.descendant(of: _title(folderName), matching: find.byType(RichText)),
  );

  return paragraph.text.style ?? const TextStyle();
}

void main() {
  testWidgets('FolderHeader property titles the folder like .folder-name', (
    tester,
  ) async {
    useDesktopSurface(tester);
    for (final example in _headerExamples(8)) {
      final colors = DesignColors.forBrightness(example.brightness);

      await tester.pumpWidget(
        hostedInTheme(
          _Header().header(example.ancestors, example.folderName),
          brightness: example.brightness,
        ),
      );

      final style = _titleStyle(tester, example.folderName);
      final title = tester.getSize(_title(example.folderName));

      expect(style.fontSize, 32);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.letterSpacing, closeTo(0.41 - 0.32, 1e-9));
      expect(style.color, colors.ink);
      expect(title.height, closeTo(32 * 1.55, 0.5));
    }
  });

  testWidgets('FolderHeader property sizes actions like .folder-actions', (
    tester,
  ) async {
    useDesktopSurface(tester);
    for (final example in _headerExamples(6)) {
      final header = _Header();

      await tester.pumpWidget(
        hostedInLightTheme(
          header.header(example.ancestors, example.folderName),
        ),
      );

      final area = tester.getRect(find.byType(FolderHeader));
      final title = tester.getRect(_title(example.folderName));
      final buttons = tester
          .widgetList<DesignButton>(find.byType(DesignButton))
          .toList();
      final newFolder = tester.getRect(find.byType(DesignButton).at(0));
      final import = tester.getRect(find.byType(DesignButton).at(1));

      expect(
        [for (final button in buttons) button.label],
        ['New folder', 'Import'],
      );
      expect(
        [for (final button in buttons) button.icon],
        [DesignIcons.newFolder, DesignIcons.aiImport],
      );
      expect(
        [for (final button in buttons) button.size],
        [ButtonSize.small, ButtonSize.small],
      );
      expect(
        [for (final button in buttons) button.variant],
        [ButtonVariant.standard, ButtonVariant.standard],
      );
      expect(newFolder.height, 34);
      expect(import.left - newFolder.right, 8);
      expect(import.right, area.right);
      expect(import.center.dy, closeTo(title.center.dy, 0.01));
      expect(title.left, area.left);

      await tester.tap(find.text('New folder'));
      await tester.tap(find.text('Import'));

      expect(header.pressed, ['new folder', 'import']);
    }
  });

  testWidgets('FolderHeader property shows crumbs only inside a subfolder', (
    tester,
  ) async {
    useDesktopSurface(tester);
    for (final example in _headerExamples(10)) {
      final colors = DesignColors.forBrightness(example.brightness);

      await tester.pumpWidget(
        hostedInTheme(
          _Header().header(example.ancestors, example.folderName),
          brightness: example.brightness,
        ),
      );

      if (example.ancestors.isEmpty) {
        expect(find.byType(FolderCrumbs), findsNothing);
        expect(
          tester.getRect(_title(example.folderName)).top,
          tester.getRect(find.byType(FolderHeader)).top,
        );
        continue;
      }

      final crumbs = find.byType(FolderCrumbs);
      final crumbTexts = [
        for (final ancestor in example.ancestors) ancestor.name,
        example.folderName,
      ];
      final chevrons = find.descendant(
        of: crumbs,
        matching: find.byType(DesignIcon),
      );
      final title = tester.getRect(_title(example.folderName));
      final homeStyle = renderedStyleOf(tester, crumbHome);

      expect(chevrons, findsNWidgets(crumbTexts.length - 1));

      for (var index = 0; index < crumbTexts.length - 1; index++) {
        final crumb = tester.getRect(
          find.descendant(of: crumbs, matching: find.text(crumbTexts[index])),
        );
        final nextCrumb = tester.getRect(
          find.descendant(
            of: crumbs,
            matching: find.text(crumbTexts[index + 1]),
          ),
        );
        final chevron = tester.getRect(chevrons.at(index));

        expect(chevron.size, const Size.square(18));
        expect(chevron.left - crumb.right, 8);
        expect(nextCrumb.left - chevron.right, 8);
        expect(
          tester.widget<DesignIcon>(chevrons.at(index)).icon,
          DesignIcons.chevronRight,
        );
      }

      expect(title.top - tester.getRect(crumbs).bottom, 16);
      expect(homeStyle.fontSize, 14);
      expect(homeStyle.color, colors.inkTertiary);
    }
  });

  testWidgets('NewFolderButton property is a small New folder .btn', (
    tester,
  ) async {
    for (final presses in examplesOf(
      (random) => integerBetween(random, 1, 3),
      runs: 3,
    )) {
      var pressed = 0;

      await tester.pumpWidget(
        hostedInLightTheme(
          Center(child: NewFolderButton(onPressed: () => pressed++)),
        ),
      );

      final button = tester.widget<DesignButton>(find.byType(DesignButton));

      for (var press = 0; press < presses; press++) {
        await tester.tap(find.text('New folder'));
      }

      expect(button.icon, DesignIcons.newFolder);
      expect(button.size, ButtonSize.small);
      expect(tester.getSize(find.byType(DesignButton)).height, 34);
      expect(pressed, presses);
    }
  });

  testWidgets('ImportButton property is a small Import .btn', (tester) async {
    for (final presses in examplesOf(
      (random) => integerBetween(random, 1, 3),
      runs: 3,
    )) {
      var pressed = 0;

      await tester.pumpWidget(
        hostedInLightTheme(
          Center(child: ImportButton(onPressed: () => pressed++)),
        ),
      );

      final button = tester.widget<DesignButton>(find.byType(DesignButton));

      for (var press = 0; press < presses; press++) {
        await tester.tap(find.text('Import'));
      }

      expect(button.icon, DesignIcons.aiImport);
      expect(button.variant, ButtonVariant.standard);
      expect(button.size, ButtonSize.small);
      expect(pressed, presses);
    }
  });
}
