import 'import_api.dart';
import 'import_source.dart';
import 'stored_source_files.dart';

class SourceTextReader {
  const SourceTextReader({required this.api, required this.storedFiles});

  final ImportApi api;
  final StoredSourceFiles storedFiles;

  Future<String> read(ImportSource source) async {
    switch (source) {
      case FileImportSource():
        final fileId = await storedFiles.store(source.file);
        final extraction = StoredFileExtraction(
          fileId: fileId,
          pages: source.pages,
        );

        return api.extractText(extraction);
      case StoredFileImportSource():
        final extraction = StoredFileExtraction(
          fileId: source.fileId,
          pages: PageSelection.wholeDocument,
        );

        return api.extractText(extraction);
      case LinkImportSource():
        return api.extractText(LinkExtraction(address: source.address));
      case PastedTextImportSource():
        return source.text;
      case TopicImportSource():
        return source.topic;
    }
  }
}
