import '../api/api_client.dart';
import '../api/json_reading.dart';
import 'generation_request.dart';
import 'generation_tasks.dart';
import 'import_source.dart';

class ImportApi {
  const ImportApi(this.client);

  final ApiClient client;

  Future<String> uploadFile({
    required String folderId,
    required UploadedFile file,
  }) async {
    final reply = await client.uploadFiles(
      '/upload-files',
      {'folder_id': folderId},
      [file],
    );
    final storedFiles = readObjects(asObject(reply), 'file_metadata');

    if (storedFiles.length != 1) {
      throw const FormatException('Expected exactly one stored file');
    }

    return readText(storedFiles.single, 'file_id');
  }

  Future<String> extractText(TextExtraction extraction) async {
    final reply = await client.sendJson(
      'POST',
      '/extract-text',
      extraction.toJson(),
    );

    return readText(asObject(reply), 'text');
  }

  Future<List<GenerationTask>> generateStudyUnits(
    GenerationRequest request,
  ) async {
    final reply = await client.sendJson(
      'POST',
      '/generate-study-units',
      request.toJson(),
    );

    return generationTasksFromJson(asObject(reply));
  }

  Future<TaskOutcome> taskOutcome(GenerationTask task) async {
    final statusPath = '${task.kind.statusPath}${Uri.encodeComponent(task.id)}';
    final reply = await client.getJson(statusPath);

    return TaskOutcome.fromStatus(readText(asObject(reply), 'status'));
  }
}
