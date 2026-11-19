import 'dart:typed_data';

import '../../shared/api/api_client.dart';
import '../../shared/api/json_reading.dart';
import '../../shared/navigation/routes.dart';
import 'file_models.dart';

const String _bookmarkPath = '/file-bookmark';

class FilesApi {
  const FilesApi(this.client);

  final ApiClient client;

  Future<Uint8List> fetchPdf(FileArguments file) {
    return client.getBytes('/file', {
      'file_id': file.id,
      'file_extension': file.extension,
    });
  }

  Future<StoredFileDetails> readFileDetails(String fileId) async {
    final reply = await client.getJson(_bookmarkPath, {'file_id': fileId});

    return StoredFileDetails.fromJson(asObject(reply));
  }

  Future<int> bookmarkPage({required String fileId, required int page}) async {
    final reply = await client.sendJson('PUT', _bookmarkPath, {
      'file_id': fileId,
      'page': page,
    });

    return readWholeNumber(asObject(reply), 'page');
  }

  Future<void> removeBookmark(String fileId) async {
    await client.delete(_bookmarkPath, {'file_id': fileId});
  }
}
