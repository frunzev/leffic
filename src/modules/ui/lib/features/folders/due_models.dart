import '../../shared/api/json_reading.dart';
import '../../shared/progress/study_progress.dart';

class StudyCount {
  const StudyCount({required this.due, required this.done});

  factory StudyCount.fromFlashcardsJson(JsonObject json) {
    return StudyCount(
      due: readWholeNumber(json, 'due'),
      done: readWholeNumber(json, 'done'),
    );
  }

  factory StudyCount.fromTestItemsJson(JsonObject json) {
    final total = readWholeNumber(json, 'total');
    final correct = readWholeNumber(json, 'correct');

    final due = countRemaining(done: correct, total: total);

    return StudyCount(due: due, done: correct);
  }

  factory StudyCount.fromNotesJson(JsonObject json) {
    return StudyCount(
      due: readWholeNumber(json, 'due'),
      done: readWholeNumber(json, 'read'),
    );
  }

  static const StudyCount nothing = StudyCount(due: 0, done: 0);

  final int due;
  final int done;
}

class DueSummary {
  const DueSummary({
    required this.flashcards,
    required this.testItems,
    required this.notes,
  });

  final StudyCount flashcards;
  final StudyCount testItems;
  final StudyCount notes;

  int get dueCount => flashcards.due + testItems.due + notes.due;

  int get doneCount => flashcards.done + testItems.done + notes.done;

  int get totalCount => dueCount + doneCount;

  int get reviewableCount => flashcards.due + testItems.due;

  double get completedShare {
    if (totalCount == 0) {
      return 0;
    }

    return doneCount / totalCount;
  }
}
