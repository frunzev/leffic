import 'package:file_selector/file_selector.dart';

import '../api/api_client.dart';

typedef SourceFilePicker = Future<UploadedFile?> Function();

Future<UploadedFile?> pickSourceFileFromDisk() async {
  final pickedFile = await openFile();

  if (pickedFile == null) {
    return null;
  }

  final bytes = await pickedFile.readAsBytes();

  return UploadedFile(name: pickedFile.name, bytes: bytes);
}
