import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/api/api_client.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/import/import_api.dart';
import 'package:leffic/shared/import/import_dialog.dart';
import 'package:leffic/shared/import/import_source.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';

const String extractedText = 'Text the backend extracted';

Map<String, ReplyToRequest> importReplies() {
  return {
    '/upload-files': answerWith({
      'file_metadata': [
        {'file_id': 'stored-file'},
      ],
    }),
    '/extract-text': answerWith({'text': extractedText}),
    '/generate-study-units': answerWith({
      'note_task_id': 'note-task',
      'flashcard_task_ids': ['flashcards-task'],
    }),
    '/note-task-status/note-task': answerWith({'status': 'SUCCESS'}),
    '/flashcards-status/flashcards-task': answerWith({'status': 'SUCCESS'}),
  };
}

Future<List<bool>> openImport(
  WidgetTester tester,
  FakeBackend backend, {
  UploadedFile? pickedFile,
}) async {
  final answers = <bool>[];

  useDesktopSurface(tester);
  await tester.pumpWidget(
    hostedPlainly(
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            final answer = await showImportDialog(
              context: context,
              api: ImportApi(backend.client()),
              folderId: 'target-folder',
              folderName: 'Biology',
              pickFile: () async => pickedFile,
              pollInterval: Duration.zero,
            );

            answers.add(answer);
          },
          child: const Text('open import'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open import'));
  await tester.pumpAndSettle();

  return answers;
}

bool isButtonEnabled(WidgetTester tester, String label) {
  final button = tester.widget<DesignButton>(
    find.widgetWithText(DesignButton, label),
  );

  return button.onPressed != null;
}

Future<void> chooseSource(WidgetTester tester, ImportSourceKind kind) async {
  await tester.tap(find.text(kind.label));
  await tester.pumpAndSettle();
}

Future<void> continueToReview(WidgetTester tester) async {
  await tester.tap(find.text('Continue'));
  await tester.pump();
  await tester.pump();
  await tester.pumpAndSettle();
}

UploadedFile namedTextFile(String name) {
  return UploadedFile(name: name, bytes: Uint8List.fromList(name.codeUnits));
}
