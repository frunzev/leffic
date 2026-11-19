import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/import/generation_request.dart';
import 'package:leffic/shared/import/generation_tasks.dart';
import 'package:leffic/shared/import/import_api.dart';
import 'package:leffic/shared/import/import_source.dart';

import '../../support/backend_fakes.dart';
import '../../support/property.dart';
import 'import_fakes.dart';

void main() {
  test('uploadFile property sends the file into the folder', () async {
    for (final (folderId, file, storedId) in examplesOf(
      (random) => (
        tokenOf(random),
        generatedFile(random, oneOf(random, pagedExtensions)),
        tokenOf(random),
      ),
      runs: 20,
    )) {
      final backend = FakeBackend({
        '/upload-files': answerWith({
          'msg': 'Files uploaded!',
          'file_metadata': [
            {'file_id': storedId, 'extension': 'pdf', 'name': file.name},
          ],
        }),
      });

      final fileId = await ImportApi(backend.client())
          .uploadFile(folderId: folderId, file: file);
      final request = backend.received.single;

      expect(request.method, 'POST');
      expect(request.headers['content-type'], startsWith('multipart/'));
      expect(request.body, contains('name="folder_id"\r\n\r\n$folderId'));
      expect(request.body, contains('filename="${file.name}"'));
      expect(fileId, storedId);
    }
  });

  test(
    'uploadFile property fails fast without exactly one stored file',
    () async {
      for (final count in examplesOf(
        (random) => oneOf(random, [0, 2, 3]),
        runs: 20,
      )) {
        final backend = FakeBackend({
          '/upload-files': answerWith({
            'file_metadata': [
              for (var index = 0; index < count; index++) {'file_id': '$index'},
            ],
          }),
        });

        await expectLater(
          ImportApi(backend.client()).uploadFile(
            folderId: 'folder',
            file: generatedFile(Random(count), 'pdf'),
          ),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'extractText property posts the extraction and reads the text',
    () async {
      for (final (extraction, text) in examplesOf(
        (random) => (
          oneOf<TextExtraction>(random, [
            StoredFileExtraction(
              fileId: tokenOf(random),
              pages: generatedPages(random),
            ),
            LinkExtraction(address: 'https://${wordOf(random)}.com'),
          ]),
          anyTextOf(random),
        ),
        runs: 20,
      )) {
        final backend = FakeBackend({
          '/extract-text': answerWith({'text': text}),
        });

        final extracted = await ImportApi(backend.client())
            .extractText(extraction);
        final request = backend.received.single;

        expect(request.method, 'POST');
        expect(sentBody(request), extraction.toJson());
        expect(extracted, text);
      }
    },
  );

  test(
    'generateStudyUnits property posts the request and lists tasks',
    () async {
      for (final request in examplesOf(
        (random) => GenerationRequest(
          text: wordOf(random),
          folderId: tokenOf(random),
          source: generatedSource(random),
          choices: generatedChoices(random),
        ),
        runs: 20,
      )) {
        final backend = FakeBackend({
          '/generate-study-units': answerWith({
            'note_task_id': 'note-task',
            'flashcard_deck_id': 'deck',
            'flashcard_task_ids': ['flashcards-task'],
          }),
        });

        final tasks = await ImportApi(backend.client())
            .generateStudyUnits(request);

        expect(sentBody(backend.received.single), request.toJson());
        expect(
          [for (final task in tasks) task.kind],
          [GeneratedKind.flashcards, GeneratedKind.note],
        );
      }
    },
  );

  test('taskOutcome property asks the status route of the task kind', () async {
    for (final (task, status) in examplesOf(
      (random) => (
        GenerationTask(
          kind: oneOf(random, GeneratedKind.values),
          id: '${tokenOf(random)}.${tokenOf(random)}',
        ),
        oneOf(random, ['PENDING', 'STARTED', 'SUCCESS', 'FAILURE']),
      ),
      runs: 20,
    )) {
      final statusPath = '${task.kind.statusPath}${task.id}';
      final backend = FakeBackend({
        statusPath: answerWith({'status': status}),
      });

      final outcome = await ImportApi(backend.client()).taskOutcome(task);

      expect(backend.received.single.method, 'GET');
      expect(backend.received.single.url.path, statusPath);
      expect(outcome, TaskOutcome.fromStatus(status));
    }
  });
}
