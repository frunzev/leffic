import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:leffic/features/files/file_models.dart';
import 'package:leffic/shared/api/json_reading.dart';
import 'package:leffic/shared/navigation/routes.dart';

import '../../support/property.dart';

const int _okStatus = 200;
const Map<String, String> _pdfHeaders = {'content-type': 'application/pdf'};
const List<String> _fileExtensions = ['pdf', 'docx', 'pptx', 'xlsx', 'txt'];

http.Response pdfReply(Uint8List pdfBytes) {
  return http.Response.bytes(pdfBytes, _okStatus, headers: _pdfHeaders);
}

FileArguments generatedFile(Random random) {
  final extension = oneOf(random, _fileExtensions);

  return FileArguments(
    id: tokenOf(random),
    name: '${wordOf(random)}.$extension',
    extension: extension,
  );
}

Uint8List generatedPdfBytes(Random random) {
  final length = integerBetween(random, 0, 2000);
  final pdfBytes = Uint8List(length);

  for (var index = 0; index < length; index++) {
    pdfBytes[index] = random.nextInt(256);
  }

  return pdfBytes;
}

int? generatedBookmarkedPage(Random random) {
  return oneOf(random, [null, integerBetween(random, 1, 500)]);
}

JsonObject generatedFileDetailsJson(Random random) {
  final pageCount = integerBetween(random, 1, 500);
  final bookmarkedPage = oneOf(random, [
    null,
    integerBetween(random, 1, pageCount),
  ]);

  return {
    'page': bookmarkedPage,
    'page_count': pageCount,
    'folder_id': tokenOf(random),
    'folder_name': wordOf(random),
  };
}

StoredFileDetails generatedFileDetails(Random random) {
  return StoredFileDetails.fromJson(generatedFileDetailsJson(random));
}

StoredFileDetails detailsOpenedAt(int? bookmarkedPage, {int pageCount = 900}) {
  return StoredFileDetails(
    bookmarkedPage: bookmarkedPage,
    pageCount: pageCount,
    folderId: 'folder',
    folderName: 'Biology',
  );
}
