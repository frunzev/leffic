import '../api/api_client.dart';
import 'import_source.dart';

const int _firstPageNumber = 1;

sealed class DraftReading {
  const DraftReading();
}

final class SourceReady extends DraftReading {
  const SourceReady({required this.source});

  final ImportSource source;
}

final class SourceMissing extends DraftReading {
  const SourceMissing({required this.reason});

  final String reason;
}

class ImportDraft {
  const ImportDraft({
    required this.kind,
    required this.file,
    required this.link,
    required this.pastedText,
    required this.topic,
    required this.firstPageText,
    required this.lastPageText,
  });

  final ImportSourceKind kind;
  final UploadedFile? file;
  final String link;
  final String pastedText;
  final String topic;
  final String firstPageText;
  final String lastPageText;

  DraftReading read() {
    return switch (kind) {
      ImportSourceKind.file => _readFile(),
      ImportSourceKind.link => _readLink(),
      ImportSourceKind.text => _readPastedText(),
      ImportSourceKind.topic => _readTopic(),
    };
  }

  DraftReading _readFile() {
    final chosenFile = file;

    if (chosenFile == null) {
      return const SourceMissing(reason: 'Choose a file first.');
    }

    if (!isPagedFileName(chosenFile.name)) {
      return SourceReady(
        source: FileImportSource(
          file: chosenFile,
          pages: PageSelection.wholeDocument,
        ),
      );
    }

    return _readPagedFile(chosenFile);
  }

  DraftReading _readPagedFile(UploadedFile chosenFile) {
    final firstText = firstPageText.trim();
    final lastText = lastPageText.trim();
    final first = int.tryParse(firstText);
    final last = int.tryParse(lastText);

    final isFirstValid = firstText.isEmpty || _isPageNumber(first);
    final isLastValid = lastText.isEmpty || _isPageNumber(last);

    if (!isFirstValid || !isLastValid) {
      return const SourceMissing(reason: 'Pages are whole numbers from 1.');
    }

    if (first != null && last != null && last < first) {
      return const SourceMissing(
        reason: 'The last page comes before the first.',
      );
    }

    final pages = PageSelection(first: first, last: last);

    return SourceReady(
      source: FileImportSource(file: chosenFile, pages: pages),
    );
  }

  bool _isPageNumber(int? page) {
    return page != null && page >= _firstPageNumber;
  }

  DraftReading _readLink() {
    final address = link.trim();

    if (address.isEmpty) {
      return const SourceMissing(reason: 'Paste a link first.');
    }

    return SourceReady(source: LinkImportSource(address: address));
  }

  DraftReading _readPastedText() {
    if (pastedText.trim().isEmpty) {
      return const SourceMissing(reason: 'Paste some text first.');
    }

    return SourceReady(source: PastedTextImportSource(text: pastedText));
  }

  DraftReading _readTopic() {
    final namedTopic = topic.trim();

    if (namedTopic.isEmpty) {
      return const SourceMissing(reason: 'Name a topic first.');
    }

    return SourceReady(source: TopicImportSource(topic: namedTopic));
  }
}
