import 'note_models.dart';
import 'notes_api.dart';

typedef OpenedNote = ({Note note, NotesProgress progress});

Future<OpenedNote> openNoteWithProgress({
  required NotesApi api,
  required String noteId,
}) async {
  final note = await api.openNote(noteId);
  final progress = await api.folderNotesProgress(note.folderId);

  return (note: note, progress: progress);
}
