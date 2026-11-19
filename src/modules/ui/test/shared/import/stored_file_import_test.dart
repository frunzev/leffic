import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/import/import_api.dart';
import 'package:leffic/shared/import/import_dialog.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import '../../support/property.dart';
import 'import_dialog_harness.dart';

typedef _StoredFile = ({String fileId, String fileName, String folderId});

_StoredFile _generatedStoredFile(Random random) {
  return (
    fileId: tokenOf(random),
    fileName: '${wordOf(random)}.pdf',
    folderId: tokenOf(random),
  );
}

Future<void> _openStoredFileImport(
  WidgetTester tester,
  FakeBackend backend,
  _StoredFile storedFile,
) async {
  useDesktopSurface(tester);
  await tester.pumpWidget(
    hostedPlainly(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showStoredFileImportDialog(
            context: context,
            api: ImportApi(backend.client()),
            fileId: storedFile.fileId,
            fileName: storedFile.fileName,
            folderId: storedFile.folderId,
            folderName: 'Biology',
            pickFile: () async => null,
            pollInterval: Duration.zero,
          ),
          child: const Text('generate from file'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('generate from file'));
}

void main() {
  testWidgets('showStoredFileImportDialog property reads it at once', (
    tester,
  ) async {
    for (final storedFile in examplesOf(_generatedStoredFile, runs: 3)) {
      final pendingText = Completer<http.Response>();
      final backend = FakeBackend({
        ...importReplies(),
        '/extract-text': (request) => pendingText.future,
      });

      await _openStoredFileImport(tester, backend, storedFile);
      await tester.pump();
      await tester.pump();

      expect(find.text('Saved into Biology.'), findsOneWidget);
      expect(find.text('Reading ${storedFile.fileName}…'), findsOneWidget);
      expect(sentBody(backend.sentTo('/extract-text').single), {
        'file_metadata': [
          {'file_id': storedFile.fileId},
        ],
      });
      expect(backend.sentTo('/upload-files'), isEmpty);

      pendingText.complete(jsonReply({'text': extractedText}));
      await tester.pumpAndSettle();

      expect(find.text('From ${storedFile.fileName}'), findsOneWidget);
      expect(find.text(extractedText), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Close dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Saved into Biology.'), findsNothing);
    }
  });

  testWidgets('showStoredFileImportDialog property generates into its folder', (
    tester,
  ) async {
    for (final storedFile in examplesOf(_generatedStoredFile, runs: 3)) {
      final backend = FakeBackend(importReplies());

      await _openStoredFileImport(tester, backend, storedFile);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(DesignButton, 'Generate'));
      await tester.pumpAndSettle();

      final generation = sentBody(
        backend.sentTo('/generate-study-units').single,
      );

      expect(generation['text'], extractedText);
      expect(generation['folder_id'], storedFile.folderId);
      expect(generation['source_kind'], 'file');
      expect(generation['source_reference'], storedFile.fileName);
      expect(backend.sentTo('/upload-files'), isEmpty);
      expect(find.text('Note ready'), findsOneWidget);
    }
  });
}
