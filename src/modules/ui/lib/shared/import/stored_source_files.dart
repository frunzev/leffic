import '../api/api_client.dart';
import 'import_api.dart';

class StoredSourceFiles {
  StoredSourceFiles({required this.api, required this.folderId});

  final ImportApi api;
  final String folderId;
  final Map<UploadedFile, String> _storedFileIds = {};

  bool get isAnyStored => _storedFileIds.isNotEmpty;

  Future<String> store(UploadedFile file) async {
    final knownFileId = _storedFileIds[file];

    if (knownFileId != null) {
      return knownFileId;
    }

    final fileId = await api.uploadFile(folderId: folderId, file: file);

    _storedFileIds[file] = fileId;

    return fileId;
  }
}
