import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/flashcards/flashcard_models.dart';
import 'package:leffic/shared/api/json_reading.dart';

import '../../support/property.dart';
import 'flashcard_generators.dart';

DateTime? _expectedMoment(Object? timestamp) {
  if (timestamp == null) {
    return null;
  }

  return parseServerTimestamp(timestamp as String);
}

void main() {
  test('parseServerTimestamp property reads the server text as UTC', () {
    forAll(generatedUtcMoment, (moment) {
      final parsed = parseServerTimestamp(serverTimestamp(moment));

      expect(parsed.isUtc, isTrue);
      expect(parsed, moment);
    });
  });

  test('parseServerTimestamp property refuses text that is no date', () {
    forAll(wordOf, (word) {
      expect(() => parseServerTimestamp('x$word'), throwsFormatException);
    });
  });

  test('FlashcardRating property scores run from 1 to 4 in order', () {
    forAll((random) => oneOf(random, FlashcardRating.values), (rating) {
      expect(rating.score, rating.index + 1);
      expect(rating.label, isNotEmpty);
    });
  });

  test('Flashcard.fromJson property reads id, face and schedule', () {
    forAll((random) => generatedFlashcardJson(random, random.nextInt(900)), (
      json,
    ) {
      final card = Flashcard.fromJson(json);

      expect(card.id, json['id']);
      expect(card.face.toContent(), json['content']);
      expect(card.nextReview, _expectedMoment(json['next_review']));
      expect(card.schedulingState, json['fsrs_card']);
    });
  });

  test('Flashcard.fromJson property fails fast on a missing id', () {
    forAll((random) => generatedFlashcardJson(random, 1), (json) {
      final broken = Map.of(json)..remove('id');

      expect(() => Flashcard.fromJson(broken), throwsFormatException);
    });
  });

  test('Flashcard.withFace property changes only the face', () {
    forAll((random) => (generatedFlashcard(random, 7), generatedFace(random)), (
      example,
    ) {
      final (card, face) = example;
      final edited = card.withFace(face);

      expect(edited.face, same(face));
      expect(edited.id, card.id);
      expect(edited.nextReview, card.nextReview);
      expect(edited.schedulingState, card.schedulingState);
    });
  });

  test('Flashcard.rescheduled property takes the outcome schedule', () {
    forAll(
      (random) => (
        generatedFlashcard(random, 3),
        ReviewOutcome(
          dueDate: generatedUtcMoment(random),
          schedulingState: generatedSchedulingState(random),
        ),
      ),
      (example) {
        final (card, outcome) = example;
        final rescheduled = card.rescheduled(outcome);

        expect(rescheduled.nextReview, outcome.dueDate);
        expect(rescheduled.schedulingState, outcome.schedulingState);
        expect(rescheduled.face, same(card.face));
        expect(rescheduled.id, card.id);
      },
    );
  });

  test('DueFlashcards.fromJson property keeps the order and the total', () {
    forAll(generatedDueJson, (json) {
      final due = DueFlashcards.fromJson(json);
      final sentCards = readObjects(json, 'flashcards');

      expect(due.totalCount, json['total_flashcards']);
      expect(due.cards.length, sentCards.length);

      for (var index = 0; index < sentCards.length; index++) {
        expect(due.cards[index].id, sentCards[index]['id']);
      }
    });
  });

  test('RatingIntervals.fromJson property reads each rating by score', () {
    forAll(generatedIntervalsJson, (json) {
      final intervals = RatingIntervals.fromJson(json);

      for (final rating in FlashcardRating.values) {
        expect(intervals.secondsFor(rating), json['${rating.score}']);
      }
    });
  });

  test('RatingIntervals.fromJson property fails fast without a rating', () {
    forAll(
      (random) =>
          (generatedIntervalsJson(random), integerBetween(random, 1, 4)),
      (example) {
        final (json, missingScore) = example;
        final broken = Map.of(json)..remove('$missingScore');

        expect(() => RatingIntervals.fromJson(broken), throwsFormatException);
      },
    );
  });

  test('ReviewOutcome.fromJson property reads the due date and state', () {
    forAll(
      (random) =>
          (generatedUtcMoment(random), generatedSchedulingState(random)),
      (example) {
        final (dueDate, state) = example;
        final outcome = ReviewOutcome.fromJson({
          'due_date': serverTimestamp(dueDate),
          'new_fsrs_card': state,
        });

        expect(outcome.dueDate, dueDate);
        expect(outcome.schedulingState, state);
      },
    );
  });

  test('ReviewOutcome.fromJson property fails fast without a new state', () {
    forAll(generatedUtcMoment, (dueDate) {
      expect(
        () => ReviewOutcome.fromJson({'due_date': serverTimestamp(dueDate)}),
        throwsFormatException,
      );
    });
  });
}
