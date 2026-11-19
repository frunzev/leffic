import '../../shared/api/json_reading.dart';
import 'flashcard_faces.dart';

const String _utcMarker = 'Z';

enum FlashcardRating {
  again(score: 1, label: 'Again'),
  hard(score: 2, label: 'Hard'),
  good(score: 3, label: 'Good'),
  easy(score: 4, label: 'Easy');

  const FlashcardRating({required this.score, required this.label});

  final int score;
  final String label;
}

DateTime parseServerTimestamp(String timestamp) {
  return DateTime.parse('$timestamp$_utcMarker');
}

DateTime? _readTimestampOrNothing(JsonObject json, String key) {
  if (json[key] == null) {
    return null;
  }

  return parseServerTimestamp(readText(json, key));
}

JsonObject? _readObjectOrNothing(JsonObject json, String key) {
  if (json[key] == null) {
    return null;
  }

  return readObject(json, key);
}

class Flashcard {
  const Flashcard({
    required this.id,
    required this.face,
    required this.nextReview,
    required this.schedulingState,
  });

  factory Flashcard.fromJson(JsonObject json) {
    final face = FlashcardFace.fromContent(
      type: readText(json, 'type'),
      content: readObject(json, 'content'),
    );

    return Flashcard(
      id: readWholeNumber(json, 'id'),
      face: face,
      nextReview: _readTimestampOrNothing(json, 'next_review'),
      schedulingState: _readObjectOrNothing(json, 'fsrs_card'),
    );
  }

  final int id;
  final FlashcardFace face;
  final DateTime? nextReview;
  final JsonObject? schedulingState;

  Flashcard withFace(FlashcardFace editedFace) {
    return Flashcard(
      id: id,
      face: editedFace,
      nextReview: nextReview,
      schedulingState: schedulingState,
    );
  }

  Flashcard rescheduled(ReviewOutcome outcome) {
    return Flashcard(
      id: id,
      face: face,
      nextReview: outcome.dueDate,
      schedulingState: outcome.schedulingState,
    );
  }
}

class DueFlashcards {
  const DueFlashcards({required this.totalCount, required this.cards});

  factory DueFlashcards.fromJson(JsonObject json) {
    final cards = <Flashcard>[];

    for (final entry in readObjects(json, 'flashcards')) {
      cards.add(Flashcard.fromJson(entry));
    }

    return DueFlashcards(
      totalCount: readWholeNumber(json, 'total_flashcards'),
      cards: cards,
    );
  }

  final int totalCount;
  final List<Flashcard> cards;
}

class RatingIntervals {
  const RatingIntervals._(this._secondsByRating);

  factory RatingIntervals.fromJson(JsonObject json) {
    final secondsByRating = <FlashcardRating, int>{};

    for (final rating in FlashcardRating.values) {
      secondsByRating[rating] = readWholeNumber(json, '${rating.score}');
    }

    return RatingIntervals._(secondsByRating);
  }

  final Map<FlashcardRating, int> _secondsByRating;

  int secondsFor(FlashcardRating rating) => _secondsByRating[rating]!;
}

class ReviewOutcome {
  const ReviewOutcome({required this.dueDate, required this.schedulingState});

  factory ReviewOutcome.fromJson(JsonObject json) {
    return ReviewOutcome(
      dueDate: parseServerTimestamp(readText(json, 'due_date')),
      schedulingState: readObject(json, 'new_fsrs_card'),
    );
  }

  final DateTime dueDate;
  final JsonObject schedulingState;
}
