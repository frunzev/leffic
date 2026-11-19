import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/notes/notes_api.dart';
import 'package:leffic/shared/api/api_error.dart';

import '../../support/backend_fakes.dart';
import '../../support/property.dart';
import 'note_fakes.dart';

void main() {
  test('openNote property asks for the note and parses it', () async {
    for (final (noteId, noteJson) in examplesOf(
      (random) => (tokenOf(random), generatedNoteJson(random)),
    )) {
      final backend = FakeBackend({'/note': answerWith(noteJson)});

      final note = await NotesApi(backend.client()).openNote(noteId);
      final request = backend.received.single;

      expect(request.method, 'GET');
      expect(request.url.path, '/note');
      expect(request.url.queryParameters, {'note_id': noteId});
      expect(note.name, noteJson['name']);
      expect(note.content, noteJson['content']);
    }
  });

  test('markNoteRead property posts the note id', () async {
    for (final noteId in examplesOf(tokenOf)) {
      final backend = FakeBackend({
        '/review-note': answerWith({'note_id': noteId}),
      });

      await NotesApi(backend.client()).markNoteRead(noteId);
      final request = backend.received.single;

      expect(request.method, 'POST');
      expect(request.url.path, '/review-note');
      expect(sentBody(request), {'note_id': noteId});
    }
  });

  test(
    'folderNotesProgress property asks for the folder notes stats',
    () async {
      for (final (folderId, statsJson) in examplesOf(
        (random) => (tokenOf(random), generatedNotesStatsJson(random)),
      )) {
        final backend = FakeBackend({'/notes-stats': answerWith(statsJson)});

        final progress = await NotesApi(backend.client())
            .folderNotesProgress(folderId);
        final request = backend.received.single;

        expect(request.method, 'GET');
        expect(request.url.queryParameters, {'folder_id': folderId});
        expect(progress.read, statsJson['read']);
      }
    },
  );

  test('NotesApi property raises the failure the backend answers', () async {
    for (final (status, detail) in examplesOf(
      (random) => (oneOf(random, [401, 404, 422, 500]), wordOf(random)),
    )) {
      final backend = FakeBackend({
        '/note': failWith(status, detail),
        '/review-note': failWith(status, detail),
        '/notes-stats': failWith(status, detail),
      });
      final api = NotesApi(backend.client());

      await expectLater(
        api.openNote('note'),
        throwsA(
          isA<ApiError>()
              .having((failure) => failure.statusCode, 'statusCode', status)
              .having((failure) => failure.detail, 'detail', detail),
        ),
      );
      await expectLater(api.markNoteRead('note'), throwsA(isA<ApiError>()));
      await expectLater(
        api.folderNotesProgress('folder'),
        throwsA(isA<ApiError>()),
      );
    }
  });
}
