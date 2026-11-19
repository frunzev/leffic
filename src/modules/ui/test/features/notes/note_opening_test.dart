import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/notes/note_opening.dart';
import 'package:leffic/features/notes/notes_api.dart';

import '../../support/backend_fakes.dart';
import '../../support/property.dart';
import 'note_fakes.dart';

void main() {
  test(
    'openNoteWithProgress property reads the progress of its folder',
    () async {
      for (final (noteId, noteJson, statsJson) in examplesOf(
        (random) => (
          tokenOf(random),
          generatedNoteJson(random),
          generatedNotesStatsJson(random),
        ),
      )) {
        final backend = FakeBackend({
          '/note': answerWith(noteJson),
          '/notes-stats': answerWith(statsJson),
        });

        final opened = await openNoteWithProgress(
          api: NotesApi(backend.client()),
          noteId: noteId,
        );
        final paths = [
          for (final request in backend.received) request.url.path,
        ];

        expect(paths, ['/note', '/notes-stats']);
        expect(backend.received.first.url.queryParameters, {'note_id': noteId});
        expect(backend.received.last.url.queryParameters, {
          'folder_id': noteJson['folder_id'],
        });
        expect(opened.note.folderId, noteJson['folder_id']);
        expect(opened.progress.read, statsJson['read']);
      }
    },
  );
}
