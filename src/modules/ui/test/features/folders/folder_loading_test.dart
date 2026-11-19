import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/folders/folder_header.dart';
import 'package:leffic/features/folders/folder_loading.dart';
import 'package:leffic/features/folders/folder_models.dart';
import 'package:leffic/features/folders/folder_skeleton.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/navigation/routes.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

void main() {
  testWidgets('FolderLoading property keeps only New folder in its header', (
    tester,
  ) async {
    for (final example in examplesOf(
      (random) => (
        folderId: oneOf(random, [homeFolderId, tokenOf(random)]),
        folderName: 'Folder ${wordOf(random)}',
      ),
      runs: 4,
    )) {
      var newFolders = 0;

      await tester.pumpWidget(
        hostedInLightTheme(
          FolderLoading(
            folderId: example.folderId,
            folderName: example.folderName,
            onNewFolder: () => newFolders++,
          ),
        ),
      );

      final buttons = tester.widgetList<DesignButton>(
        find.byType(DesignButton),
      );

      expect([for (final button in buttons) button.label], ['New folder']);
      expect(find.text(example.folderName), findsWidgets);
      expect(find.byType(DueSkeleton), findsOneWidget);
      expect(find.byType(UnitsSkeleton), findsOneWidget);

      await tester.tap(find.text('New folder'));

      expect(newFolders, 1);
    }
  });

  testWidgets('FolderLoading property crumbs only a subfolder under Home', (
    tester,
  ) async {
    for (final folderId in examplesOf(
      (random) => oneOf(random, [homeFolderId, tokenOf(random)]),
      runs: 6,
    )) {
      await tester.pumpWidget(
        hostedInLightTheme(
          FolderLoading(
            folderId: folderId,
            folderName: 'Loading folder',
            onNewFolder: () {},
          ),
        ),
      );

      final isSubfolder = folderId != homeFolderId;
      final crumbs = find.byType(FolderCrumbs);

      expect(crumbs, isSubfolder ? findsOneWidget : findsNothing);

      if (isSubfolder) {
        expect(
          find.descendant(of: crumbs, matching: find.text(homeFolderName)),
          findsOneWidget,
        );
      }
    }
  });
}
