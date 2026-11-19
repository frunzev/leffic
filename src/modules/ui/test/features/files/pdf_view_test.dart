import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/files/document_page_reports.dart';
import 'package:leffic/features/files/pdf_view.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import 'pdf_viewer_fakes.dart';

class _PageReportLog {
  final List<int> pageCounts = [];
  final List<int> visiblePages = [];

  DocumentPageReports reportsOpeningAt(int openingPage) {
    return DocumentPageReports(
      openingPage: openingPage,
      onPageCountChanged: pageCounts.add,
      onVisiblePageChanged: visiblePages.add,
    );
  }
}

(String, int, int) _openedPdf(Random random) {
  final pageCount = integerBetween(random, 1, 400);
  final openingPage = integerBetween(random, 1, pageCount);

  return ('/tmp/${wordOf(random)}.pdf', pageCount, openingPage);
}

List<int> _shownPages(Random random) {
  final shownPageCount = integerBetween(random, 1, 8);

  return [
    for (var index = 0; index < shownPageCount; index++)
      integerBetween(random, 1, 60),
  ];
}

Object? _notAPageNumber(Random random) {
  return oneOf<Object?>(random, [
    -integerBetween(random, 0, 50),
    wordOf(random),
    null,
  ]);
}

Future<void> _pumpPdfView(
  WidgetTester tester, {
  required String path,
  required DocumentPageReports pageReports,
}) async {
  await tester.pumpWidget(
    hostedPlainly(
      PdfView(key: UniqueKey(), pdf: File(path), pageReports: pageReports),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('PdfView property loads its file then opens the given page', (
    tester,
  ) async {
    for (final (path, pageCount, openingPage) in examplesOf(
      _openedPdf,
      runs: 8,
    )) {
      final viewer = FakePdfViewer(tester: tester, pageCount: pageCount)
        ..install();
      final log = _PageReportLog();

      await _pumpPdfView(
        tester,
        path: path,
        pageReports: log.reportsOpeningAt(openingPage),
      );

      final calls = [
        for (final call in viewer.receivedCalls) (call.method, call.arguments),
      ];

      expect(calls, [('loadDocument', path), ('goToPage', openingPage)]);
      expect(log.pageCounts, [pageCount]);
      expect(log.visiblePages, isEmpty);
    }
  });

  testWidgets('PdfView property reports every page the viewer shows', (
    tester,
  ) async {
    for (final shownPages in examplesOf(_shownPages, runs: 8)) {
      final viewer = FakePdfViewer(tester: tester, pageCount: 60)..install();
      final log = _PageReportLog();

      await _pumpPdfView(
        tester,
        path: '/tmp/lecture.pdf',
        pageReports: log.reportsOpeningAt(1),
      );

      for (final page in shownPages) {
        decodeViewerReply(await viewer.showVisiblePage(page));
      }

      expect(log.visiblePages, shownPages);
    }
  });

  testWidgets('PdfView property refuses a page that is not a page number', (
    tester,
  ) async {
    for (final page in examplesOf(_notAPageNumber, runs: 8)) {
      final viewer = FakePdfViewer(tester: tester, pageCount: 60)..install();
      final log = _PageReportLog();

      await _pumpPdfView(
        tester,
        path: '/tmp/lecture.pdf',
        pageReports: log.reportsOpeningAt(1),
      );

      final reply = await viewer.showVisiblePage(page);

      expect(() => decodeViewerReply(reply), throwsA(isA<PlatformException>()));
      expect(log.visiblePages, isEmpty);
    }
  });

  testWidgets('PdfView property stops listening once it is gone', (
    tester,
  ) async {
    for (final page in examplesOf(
      (random) => integerBetween(random, 1, 60),
      runs: 4,
    )) {
      final viewer = FakePdfViewer(tester: tester, pageCount: 60)..install();
      final log = _PageReportLog();

      await _pumpPdfView(
        tester,
        path: '/tmp/lecture.pdf',
        pageReports: log.reportsOpeningAt(1),
      );
      await tester.pumpWidget(hostedPlainly(const SizedBox.shrink()));

      final reply = await viewer.showVisiblePage(page);

      expect(reply, isNull);
      expect(log.visiblePages, isEmpty);
    }
  });
}
