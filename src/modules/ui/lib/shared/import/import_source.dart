import '../api/api_client.dart';
import '../api/json_reading.dart';

const List<String> pagedExtensions = [
  'pdf',
  'doc',
  'docx',
  'odt',
  'rtf',
  'ppt',
  'pptx',
  'odp',
];
const String _pastedTextLabel = 'your text';
const String _pastedTextReference = '';

enum ImportSourceKind {
  file(label: 'File'),
  link(label: 'Link'),
  text(label: 'Text'),
  topic(label: 'Topic');

  const ImportSourceKind({required this.label});

  final String label;
}

bool isPagedFileName(String fileName) {
  final lowerCaseName = fileName.toLowerCase();

  for (final extension in pagedExtensions) {
    if (lowerCaseName.endsWith('.$extension')) {
      return true;
    }
  }

  return false;
}

class PageSelection {
  const PageSelection({required this.first, required this.last});

  static const PageSelection wholeDocument = PageSelection(
    first: null,
    last: null,
  );

  final int? first;
  final int? last;

  bool get isWholeDocument => first == null && last == null;

  JsonObject toJson() {
    return {if (first != null) 'first': first, if (last != null) 'last': last};
  }
}

sealed class ImportSource {
  const ImportSource();

  String get sourceKind;

  String get reference;

  String get label;
}

final class FileImportSource extends ImportSource {
  const FileImportSource({required this.file, required this.pages});

  final UploadedFile file;
  final PageSelection pages;

  @override
  String get sourceKind => 'file';

  @override
  String get reference => file.name;

  @override
  String get label => file.name;
}

final class StoredFileImportSource extends ImportSource {
  const StoredFileImportSource({required this.fileId, required this.fileName});

  final String fileId;
  final String fileName;

  @override
  String get sourceKind => 'file';

  @override
  String get reference => fileName;

  @override
  String get label => fileName;
}

final class LinkImportSource extends ImportSource {
  const LinkImportSource({required this.address});

  final String address;

  @override
  String get sourceKind => 'link';

  @override
  String get reference => address;

  @override
  String get label => address;
}

final class PastedTextImportSource extends ImportSource {
  const PastedTextImportSource({required this.text});

  final String text;

  @override
  String get sourceKind => 'text';

  @override
  String get reference => _pastedTextReference;

  @override
  String get label => _pastedTextLabel;
}

final class TopicImportSource extends ImportSource {
  const TopicImportSource({required this.topic});

  final String topic;

  @override
  String get sourceKind => 'topic';

  @override
  String get reference => topic;

  @override
  String get label => topic;
}

sealed class TextExtraction {
  const TextExtraction();

  JsonObject toJson();
}

final class StoredFileExtraction extends TextExtraction {
  const StoredFileExtraction({required this.fileId, required this.pages});

  final String fileId;
  final PageSelection pages;

  @override
  JsonObject toJson() {
    final requestedFile = <String, Object?>{
      'file_id': fileId,
      if (!pages.isWholeDocument) 'pages': pages.toJson(),
    };

    return {
      'file_metadata': [requestedFile],
    };
  }
}

final class LinkExtraction extends TextExtraction {
  const LinkExtraction({required this.address});

  final String address;

  @override
  JsonObject toJson() => {'link_metadata': address};
}
