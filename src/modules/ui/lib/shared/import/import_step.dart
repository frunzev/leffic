import 'import_source.dart';

sealed class ImportStep {
  const ImportStep();
}

final class ChoosingSource extends ImportStep {
  const ChoosingSource();
}

final class ReadingSource extends ImportStep {
  const ReadingSource({required this.source});

  final ImportSource source;
}

final class ReviewingText extends ImportStep {
  const ReviewingText({required this.source});

  final ImportSource source;
}

ImportStep firstImportStep(ImportSource? sourceToRead) {
  if (sourceToRead == null) {
    return const ChoosingSource();
  }

  return ReadingSource(source: sourceToRead);
}
