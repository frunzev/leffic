import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/assessment/folder_test_page.dart';
import 'package:leffic/features/assessment/test_page.dart';
import 'package:leffic/features/files/file_page.dart';
import 'package:leffic/features/flashcards/deck_review_page.dart';
import 'package:leffic/features/flashcards/folder_review_page.dart';
import 'package:leffic/features/folders/folder_page.dart';
import 'package:leffic/features/notes/note_page.dart';
import 'package:leffic/features/settings/settings_page.dart';
import 'package:leffic/features/startup/startup_page.dart';
import 'package:leffic/main.dart';
import 'package:leffic/shared/navigation/routes.dart';

import 'support/property.dart';

Widget _pageAt(String route, Object? arguments) {
  return pageFor(RouteSettings(name: route, arguments: arguments));
}

void main() {
  test('pageFor property opens the page each unit route names', () {
    forAll(tokenOf, (unitId) {
      final unit = UnitArguments(id: unitId);

      expect(_pageAt(Routes.folder, unit), isA<FolderPage>());
      expect(_pageAt(Routes.deckReview, unit), isA<DeckReviewPage>());
      expect(_pageAt(Routes.folderReview, unit), isA<FolderReviewPage>());
      expect(_pageAt(Routes.test, unit), isA<TestPage>());
      expect(_pageAt(Routes.folderTest, unit), isA<FolderTestPage>());
      expect(_pageAt(Routes.note, unit), isA<NotePage>());
    });
  });

  test('pageFor property opens a file only with file arguments', () {
    forAll((random) => (tokenOf(random), wordOf(random)), (example) {
      final (fileId, extension) = example;
      final file = FileArguments(id: fileId, name: 'f', extension: extension);

      expect(_pageAt(Routes.file, file), isA<FilePage>());
      expect(
        _pageAt(Routes.file, UnitArguments(id: fileId)),
        isA<StartupPage>(),
      );
    });
  });

  test('pageFor property falls back to startup for anything unknown', () {
    forAll(wordOf, (unknownRoute) {
      expect(_pageAt('/unknown-$unknownRoute', null), isA<StartupPage>());
      expect(_pageAt(Routes.folder, null), isA<StartupPage>());
    });
    expect(_pageAt(Routes.settings, null), isA<SettingsPage>());
  });
}
