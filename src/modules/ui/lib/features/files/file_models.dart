import 'dart:io';

import '../../shared/api/json_reading.dart';

const String _pageKey = 'page';

int? bookmarkedPageFrom(JsonObject json) {
  if (json[_pageKey] == null) {
    return null;
  }

  return readWholeNumber(json, _pageKey);
}

class StoredFileDetails {
  const StoredFileDetails({
    required this.bookmarkedPage,
    required this.pageCount,
    required this.folderId,
    required this.folderName,
  });

  factory StoredFileDetails.fromJson(JsonObject json) {
    return StoredFileDetails(
      bookmarkedPage: bookmarkedPageFrom(json),
      pageCount: readWholeNumber(json, 'page_count'),
      folderId: readText(json, 'folder_id'),
      folderName: readText(json, 'folder_name'),
    );
  }

  final int? bookmarkedPage;
  final int pageCount;
  final String folderId;
  final String folderName;
}

class OpenedFile {
  const OpenedFile({required this.pdf, required this.details});

  final File pdf;
  final StoredFileDetails details;
}
