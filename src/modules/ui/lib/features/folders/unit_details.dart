import '../../shared/api/json_reading.dart';

const String _dueCountKey = 'due_count';
const String _sizeBytesKey = 'size_bytes';

sealed class UnitDetails {
  const UnitDetails();
}

final class FolderDetails extends UnitDetails {
  const FolderDetails({required this.itemCount, required this.editedAt});

  factory FolderDetails.fromJson(JsonObject json) {
    return FolderDetails(
      itemCount: readWholeNumber(json, 'item_count'),
      editedAt: DateTime.parse(readText(json, 'edited_at')),
    );
  }

  final int itemCount;
  final DateTime editedAt;
}

final class DeckDetails extends UnitDetails {
  const DeckDetails({required this.cardCount, required this.dueCount});

  factory DeckDetails.fromJson(JsonObject json) {
    return DeckDetails(
      cardCount: readWholeNumber(json, 'card_count'),
      dueCount: readWholeNumber(json, _dueCountKey),
    );
  }

  final int cardCount;
  final int dueCount;
}

final class TestDetails extends UnitDetails {
  const TestDetails({required this.questionCount, required this.dueCount});

  factory TestDetails.fromJson(JsonObject json) {
    return TestDetails(
      questionCount: readWholeNumber(json, 'question_count'),
      dueCount: readWholeNumber(json, _dueCountKey),
    );
  }

  final int questionCount;
  final int dueCount;
}

final class NoteDetails extends UnitDetails {
  const NoteDetails({required this.readingMinutes});

  factory NoteDetails.fromJson(JsonObject json) {
    return NoteDetails(
      readingMinutes: readWholeNumber(json, 'reading_minutes'),
    );
  }

  final int readingMinutes;
}

final class FileDetails extends UnitDetails {
  const FileDetails({required this.sizeBytes});

  factory FileDetails.fromJson(JsonObject json) {
    final isStored = json[_sizeBytesKey] != null;
    final sizeBytes = isStored ? readWholeNumber(json, _sizeBytesKey) : null;

    return FileDetails(sizeBytes: sizeBytes);
  }

  final int? sizeBytes;
}
