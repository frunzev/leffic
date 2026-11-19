import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/files/file_bar.dart';
import 'package:leffic/features/files/file_models.dart';
import 'package:leffic/features/files/file_opener.dart';
import 'package:leffic/shared/api/api_error.dart';
import 'package:leffic/shared/design/spinner.dart';
import 'package:leffic/shared/office/missing_libreoffice.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import 'file_fakes.dart';

Widget _opener({
  required String fileName,
  required Future<OpenedFile> Function() open,
}) {
  return hostedPlainly(
    FileOpener(
      key: UniqueKey(),
      fileName: fileName,
      open: open,
      builder: (context, opened) => Text('reading ${opened.pdf.path}'),
    ),
  );
}

void main() {
  testWidgets('FileOpener property names the file while it opens', (
    tester,
  ) async {
    for (final fileName in examplesOf(wordOf, runs: 5)) {
      final pendingFile = Completer<OpenedFile>();

      await tester.pumpWidget(
        _opener(fileName: fileName, open: () => pendingFile.future),
      );

      expect(find.text('Opening $fileName…'), findsOneWidget);
      expect(find.byType(Spinner), findsOneWidget);
      expect(find.text(fileName), findsOneWidget);
      expect(find.byType(FileBar), findsOneWidget);
    }
  });

  testWidgets('FileOpener property shows the opened file', (tester) async {
    for (final (fileName, pdfName, details) in examplesOf(
      (random) =>
          (wordOf(random), tokenOf(random), generatedFileDetails(random)),
      runs: 5,
    )) {
      final opened = OpenedFile(
        pdf: File('/tmp/$pdfName.pdf'),
        details: details,
      );

      await tester.pumpWidget(
        _opener(fileName: fileName, open: () async => opened),
      );
      await tester.pumpAndSettle();

      expect(find.text('reading ${opened.pdf.path}'), findsOneWidget);
    }
  });

  testWidgets('FileOpener property explains a failure and retries it', (
    tester,
  ) async {
    for (final (fileName, detail) in examplesOf(
      (random) => (wordOf(random), 'Conversion failed: ${wordOf(random)}'),
      runs: 5,
    )) {
      var openCount = 0;

      await tester.pumpWidget(
        _opener(
          fileName: fileName,
          open: () async {
            openCount++;

            throw ApiError(statusCode: 400, path: '/file', detail: detail);
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Couldn't open $fileName"), findsOneWidget);
      expect(find.text(detail), findsOneWidget);
      expect(find.text(fileName), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(openCount, 2);
      expect(find.text(missingLibreOfficeMessage.title), findsNothing);
    }
  });

  testWidgets('FileOpener property sends a missing LibreOffice to Settings', (
    tester,
  ) async {
    for (final (fileName, binary) in examplesOf(
      (random) => (wordOf(random), '/${tokenOf(random)}/soffice'),
      runs: 5,
    )) {
      final detail =
          'Conversion failed: LibreOffice is not installed at '
          '$binary';

      await tester.pumpWidget(
        _opener(
          fileName: fileName,
          open: () async {
            throw ApiError(statusCode: 400, path: '/file', detail: detail);
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Couldn't open $fileName"), findsOneWidget);
      expect(find.text(missingLibreOfficeMessage.title), findsOneWidget);
      expect(find.text(missingLibreOfficeMessage.detail!), findsOneWidget);
    }
  });
}
