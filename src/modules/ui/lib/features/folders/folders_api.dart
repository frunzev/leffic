import '../../shared/api/api_client.dart';
import '../../shared/api/json_reading.dart';
import '../../shared/api/json_unless_missing.dart';
import 'due_models.dart';
import 'folder_models.dart';

class FoldersApi {
  const FoldersApi(this.client);

  final ApiClient client;

  Future<FolderListing> openFolder(String folderId) async {
    final reply = await client.getJson('/access-folder/', {
      'folder_id': folderId,
    });

    return FolderListing.fromJson(asObject(reply));
  }

  Future<void> createFolder({
    required String parentFolderId,
    required String name,
  }) async {
    await client.sendJson('POST', '/create-folder', {
      'parent_folder_id': parentFolderId,
      'folder_name': name,
    });
  }

  Future<void> renameUnit({
    required FolderUnit unit,
    required String name,
  }) async {
    await client.sendJson('PATCH', '/rename-unit', {
      'unit_id': unit.id,
      'unit_type': unit.type.wireName,
      'name': name,
    });
  }

  Future<void> moveUnit({
    required FolderUnit unit,
    required String destinationFolderId,
  }) async {
    await client.sendJson('PATCH', '/move-unit', {
      'unit_id': unit.id,
      'unit_type': unit.type.wireName,
      'folder_id': destinationFolderId,
    });
  }

  Future<void> deleteUnit(FolderUnit unit) async {
    await client.delete(unit.type.deletePath, {
      unit.type.deleteQueryKey: unit.id,
    });
  }

  Future<StudyCount> flashcardsStats(String folderId) {
    return _studyCount(
      path: '/flashcards-stats',
      folderId: folderId,
      readCount: StudyCount.fromFlashcardsJson,
    );
  }

  Future<StudyCount> testItemsStats(String folderId) {
    return _studyCount(
      path: '/test-items-stats',
      folderId: folderId,
      readCount: StudyCount.fromTestItemsJson,
    );
  }

  Future<StudyCount> notesStats(String folderId) {
    return _studyCount(
      path: '/notes-stats',
      folderId: folderId,
      readCount: StudyCount.fromNotesJson,
    );
  }

  Future<StudyCount> _studyCount({
    required String path,
    required String folderId,
    required JsonReader<StudyCount> readCount,
  }) {
    return readJsonUnlessMissing(
      client: client,
      path: path,
      query: {'folder_id': folderId},
      whenMissing: StudyCount.nothing,
      read: readCount,
    );
  }
}
