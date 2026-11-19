import '../../shared/api/api_client.dart';
import '../../shared/api/json_reading.dart';
import 'note_models.dart';

class NotesApi {
  const NotesApi(this.client);

  final ApiClient client;

  Future<Note> openNote(String noteId) async {
    final reply = await client.getJson('/note', {'note_id': noteId});

    return Note.fromJson(asObject(reply));
  }

  Future<NotesProgress> folderNotesProgress(String folderId) async {
    final reply = await client.getJson('/notes-stats', {'folder_id': folderId});

    return NotesProgress.fromJson(asObject(reply));
  }

  Future<void> markNoteRead(String noteId) async {
    await client.sendJson('POST', '/review-note', {'note_id': noteId});
  }
}
