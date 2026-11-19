import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/files/document_page_reports.dart';
import 'package:leffic/features/files/file_bookmark_button.dart';
import 'package:leffic/features/files/file_models.dart';
import 'package:leffic/features/files/file_reader.dart';
import 'package:leffic/features/files/files_api.dart';
import 'package:leffic/shared/design/button_look.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';
import 'package:leffic/shared/navigation/routes.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import '../../support/property.dart';
import 'file_fakes.dart';

ReplyToRequest _bookmarkReply() {
  return (request) async {
    if (request.method == 'PUT') {
      return jsonReply({'page': sentBody(request)['page']});
    }

    return jsonReply({'page': null});
  };
}

class _DocumentSpy {
  _DocumentSpy(this.fileName);

  final String fileName;
  final List<DocumentPageReports> givenReports = [];

  DocumentPageReports get pageReports => givenReports.last;

  Widget build(DocumentPageReports pageReports) {
    givenReports.add(pageReports);

    return Text('document of $fileName');
  }
}

Future<_DocumentSpy> _pumpReader(
  WidgetTester tester, {
  required FakeBackend backend,
  required FileArguments file,
  required StoredFileDetails details,
  VoidCallback onClose = _ignoreClose,
  VoidCallback onGenerateStudyUnits = _ignoreGenerate,
}) async {
  final document = _DocumentSpy(file.name);

  await tester.pumpWidget(
    hostedPlainly(
      FileReader(
        key: UniqueKey(),
        api: FilesApi(backend.client()),
        file: file,
        details: details,
        documentBuilder: document.build,
        onGenerateStudyUnits: onGenerateStudyUnits,
        onClose: onClose,
      ),
    ),
  );

  return document;
}

List<int> _shownPages(Random random, int pageCount) {
  final shownPageCount = integerBetween(random, 1, 6);

  return [
    for (var index = 0; index < shownPageCount; index++)
      integerBetween(random, 1, pageCount),
  ];
}

(FileArguments, int, List<int>) _scrolledFile(Random random) {
  final pageCount = integerBetween(random, 1, 300);

  return (generatedFile(random), pageCount, _shownPages(random, pageCount));
}

void _ignoreClose() {}

void _ignoreGenerate() {}

void main() {
  testWidgets('FileReader property opens at the bookmark or page one', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final (file, details) in examplesOf(
      (random) => (generatedFile(random), generatedFileDetails(random)),
      runs: 10,
    )) {
      final backend = FakeBackend({'/file-bookmark': _bookmarkReply()});
      final bookmarkedPage = details.bookmarkedPage;
      final firstPage = bookmarkedPage ?? 1;

      final document = await _pumpReader(
        tester,
        backend: backend,
        file: file,
        details: details,
      );

      expect(document.pageReports.openingPage, firstPage);
      expect(
        find.text('Page $firstPage of ${details.pageCount}'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Previous page'), findsNothing);
      expect(find.bySemanticsLabel('Next page'), findsNothing);
      expect(find.text(file.extension.toUpperCase()), findsOneWidget);
      expect(find.text('document of ${file.name}'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          bookmarkLabel(pageInView: firstPage, bookmarkedPage: bookmarkedPage),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('FileReader property shows the page the document shows', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final (file, pageCount, shownPages) in examplesOf(
      _scrolledFile,
      runs: 8,
    )) {
      final backend = FakeBackend({'/file-bookmark': _bookmarkReply()});
      final document = await _pumpReader(
        tester,
        backend: backend,
        file: file,
        details: detailsOpenedAt(null),
      );

      document.pageReports.onPageCountChanged(pageCount);

      for (final page in shownPages) {
        document.pageReports.onVisiblePageChanged(page);
        await tester.pump();

        expect(find.text('Page $page of $pageCount'), findsOneWidget);
      }

      expect(backend.received, isEmpty);
    }
  });

  testWidgets('FileReader property bookmarks the page in view', (tester) async {
    useDesktopSurface(tester);

    for (final (file, pageCount, shownPages) in examplesOf(
      _scrolledFile,
      runs: 8,
    )) {
      final backend = FakeBackend({'/file-bookmark': _bookmarkReply()});
      final pageInView = shownPages.last;
      final document = await _pumpReader(
        tester,
        backend: backend,
        file: file,
        details: detailsOpenedAt(null, pageCount: pageCount),
      );

      for (final page in shownPages) {
        document.pageReports.onVisiblePageChanged(page);
      }

      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Bookmark page $pageInView'));
      await tester.pumpAndSettle();

      final request = backend.received.single;

      expect(request.method, 'PUT');
      expect(sentBody(request), {'file_id': file.id, 'page': pageInView});
      expect(
        find.bySemanticsLabel('Remove the bookmark on page $pageInView'),
        findsOneWidget,
      );
    }
  });

  testWidgets('FileReader property forgets the bookmark it opened at', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final (file, bookmarkedPage) in examplesOf(
      (random) => (generatedFile(random), integerBetween(random, 1, 300)),
      runs: 8,
    )) {
      final backend = FakeBackend({'/file-bookmark': _bookmarkReply()});

      await _pumpReader(
        tester,
        backend: backend,
        file: file,
        details: detailsOpenedAt(bookmarkedPage),
      );
      await tester.tap(
        find.bySemanticsLabel('Remove the bookmark on page $bookmarkedPage'),
      );
      await tester.pumpAndSettle();

      final request = backend.received.single;

      expect(request.method, 'DELETE');
      expect(request.url.queryParameters, {'file_id': file.id});
      expect(
        find.bySemanticsLabel('Bookmark page $bookmarkedPage'),
        findsOneWidget,
      );
    }
  });

  testWidgets('FileReader property names the file and closes it', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final (file, taps) in examplesOf(
      (random) => (generatedFile(random), integerBetween(random, 1, 3)),
      runs: 6,
    )) {
      final backend = FakeBackend({'/file-bookmark': _bookmarkReply()});
      var closeCount = 0;

      await _pumpReader(
        tester,
        backend: backend,
        file: file,
        details: detailsOpenedAt(null),
        onClose: () => closeCount++,
      );

      for (var tap = 0; tap < taps; tap++) {
        await tester.tap(find.bySemanticsLabel('Close ${file.name}'));
      }

      expect(find.text(file.name), findsOneWidget);
      expect(closeCount, taps);
      expect(backend.received, isEmpty);
    }
  });

  testWidgets('FileReader property generates study units from its file', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final (file, taps) in examplesOf(
      (random) => (generatedFile(random), integerBetween(random, 1, 3)),
      runs: 4,
    )) {
      final backend = FakeBackend({'/file-bookmark': _bookmarkReply()});
      var generateCount = 0;

      await _pumpReader(
        tester,
        backend: backend,
        file: file,
        details: detailsOpenedAt(null),
        onGenerateStudyUnits: () => generateCount++,
      );

      final button = tester.widget<DesignButton>(
        find.widgetWithText(DesignButton, 'Generate study units'),
      );

      for (var tap = 0; tap < taps; tap++) {
        await tester.tap(find.text('Generate study units'));
      }

      expect(button.icon, DesignIcons.aiImport);
      expect(button.variant, ButtonVariant.standard);
      expect(generateCount, taps);
      expect(backend.received, isEmpty);
    }
  });
}
