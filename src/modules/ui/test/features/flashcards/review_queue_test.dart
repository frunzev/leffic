import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/flashcards/flashcard_faces.dart';
import 'package:leffic/features/flashcards/flashcard_models.dart';
import 'package:leffic/features/flashcards/review_queue.dart';

import '../../support/property.dart';
import 'flashcard_generators.dart';

typedef _ReviewExample = (
  ReviewQueue queue,
  ReviewOutcome outcome,
  DateTime now,
);

ReviewQueue _generatedQueue(Random random) {
  final cards = sortedByDueDate(generatedFlashcards(random));
  final totalToReview = cards.length + integerBetween(random, 0, 10);

  return ReviewQueue(
    cards: cards,
    totalToReview: totalToReview,
    reviewedCount: integerBetween(random, 0, totalToReview),
  );
}

_ReviewExample _generatedReview(Random random) {
  final queue = _generatedQueue(random);
  final now = generatedUtcMoment(random);
  final dueDate = oneOf(random, [
    now.add(Duration(minutes: integerBetween(random, 0, 5))),
    now.add(Duration(days: integerBetween(random, 1, 90))),
    generatedUtcMoment(random),
  ]);
  final outcome = ReviewOutcome(
    dueDate: dueDate,
    schedulingState: generatedSchedulingState(random),
  );

  return (queue, outcome, now);
}

bool _isSorted(List<Flashcard> cards) {
  for (var index = 1; index < cards.length; index++) {
    final earlier = cards[index - 1].nextReview;
    final later = cards[index].nextReview;

    if (later == null && earlier != null) {
      return false;
    }

    if (earlier != null && later != null && later.isBefore(earlier)) {
      return false;
    }
  }

  return true;
}

bool _leavesQueue(ReviewQueue queue, DateTime dueDate) {
  if (queue.cards.length == 1) {
    return true;
  }

  final lastReview = queue.cards.last.nextReview;

  return lastReview == null || !dueDate.isBefore(lastReview);
}

void main() {
  test('ReviewQueue.startingWith property counts nothing reviewed yet', () {
    forAll(
      (random) => DueFlashcards(
        totalCount: integerBetween(random, 0, 40),
        cards: generatedFlashcards(random, minimum: 0),
      ),
      (due) {
        final queue = ReviewQueue.startingWith(due);

        expect(queue.cards, due.cards);
        expect(queue.totalToReview, due.totalCount);
        expect(queue.reviewedCount, 0);
      },
    );
  });

  test('ReviewQueue.refilledWith property keeps the first known total', () {
    forAll(
      (random) => (
        ReviewQueue(
          cards: const [],
          totalToReview: oneOf(random, [0, integerBetween(random, 1, 30)]),
          reviewedCount: integerBetween(random, 0, 30),
        ),
        DueFlashcards(
          totalCount: integerBetween(random, 0, 30),
          cards: generatedFlashcards(random, minimum: 0),
        ),
      ),
      (example) {
        final (queue, due) = example;
        final refilled = queue.refilledWith(due);
        final expectedTotal = queue.totalToReview == 0
            ? due.totalCount
            : queue.totalToReview;

        expect(refilled.cards, due.cards);
        expect(refilled.totalToReview, expectedTotal);
        expect(refilled.reviewedCount, queue.reviewedCount);
      },
    );
  });

  test('ReviewQueue.afterReview property counts cards that leave today', () {
    forAll(_generatedReview, (example) {
      final (queue, outcome, now) = example;
      final reviewed = queue.afterReview(outcome, now: now);
      final isDueToday = isSameUtcDay(outcome.dueDate, now);

      expect(
        reviewed.reviewedCount,
        queue.reviewedCount + (isDueToday ? 0 : 1),
      );
      expect(reviewed.totalToReview, queue.totalToReview);
    });
  });

  test('ReviewQueue.afterReview property keeps every other card', () {
    forAll(_generatedReview, (example) {
      final (queue, outcome, now) = example;
      final reviewed = queue.afterReview(outcome, now: now);
      final otherIds = idsOf(queue.cards.sublist(1));

      expect(idsOf(reviewed.cards), containsAll(otherIds));
      expect(
        reviewed.cards.length,
        anyOf(queue.cards.length, queue.cards.length - 1),
      );
    });
  });

  test('ReviewQueue.afterReview property drops a card due after the rest', () {
    forAll(_generatedReview, (example) {
      final (queue, outcome, now) = example;
      final reviewed = queue.afterReview(outcome, now: now);
      final reviewedId = queue.cards.first.id;
      final isDropped = _leavesQueue(queue, outcome.dueDate);

      expect(idsOf(reviewed.cards).contains(reviewedId), !isDropped);

      for (final card in reviewed.cards) {
        if (card.id == reviewedId) {
          expect(card.nextReview, outcome.dueDate);
          expect(card.schedulingState, outcome.schedulingState);
        }
      }
    });
  });

  test('ReviewQueue.afterReview property keeps a sorted queue sorted', () {
    forAll(_generatedReview, (example) {
      final (queue, outcome, now) = example;

      expect(_isSorted(queue.afterReview(outcome, now: now).cards), isTrue);
    });
  });

  test('ReviewQueue.afterDeletion property drops the current card', () {
    forAll(_generatedQueue, (queue) {
      final remaining = queue.afterDeletion();

      expect(idsOf(remaining.cards), idsOf(queue.cards.sublist(1)));
      expect(remaining.totalToReview, max(0, queue.totalToReview - 1));
      expect(remaining.reviewedCount, queue.reviewedCount);
    });
  });

  test('ReviewQueue.withCurrentFace property edits only the current card', () {
    forAll((random) => (_generatedQueue(random), generatedFace(random)), (
      example,
    ) {
      final (queue, face) = example;
      final edited = queue.withCurrentFace(face);

      expect(edited.current?.face, same(face));
      expect(idsOf(edited.cards), idsOf(queue.cards));

      for (var index = 1; index < queue.cards.length; index++) {
        expect(edited.cards[index], same(queue.cards[index]));
      }
    });
  });

  test('ReviewQueue.current property is the first card or nothing', () {
    forAll(
      (random) => ReviewQueue(
        cards: generatedFlashcards(random, minimum: 0),
        totalToReview: 0,
        reviewedCount: 0,
      ),
      (queue) {
        expect(queue.current, queue.cards.isEmpty ? isNull : queue.cards.first);
      },
    );
  });

  test('ReviewQueue property left count and share stay in bounds', () {
    forAll(
      (random) => ReviewQueue(
        cards: const [],
        totalToReview: integerBetween(random, 0, 50),
        reviewedCount: integerBetween(random, 0, 60),
      ),
      (queue) {
        expect(queue.leftCount, greaterThanOrEqualTo(0));
        expect(
          queue.leftCount,
          max(0, queue.totalToReview - queue.reviewedCount),
        );
        expect(queue.completedShare, inInclusiveRange(0, 1));
      },
    );
  });

  test('sortedByDueDate property puts new cards first, then by due date', () {
    forAll(generatedFlashcards, (cards) {
      final sorted = sortedByDueDate(cards);

      expect(_isSorted(sorted), isTrue);
      expect(idsOf(sorted), unorderedEquals(idsOf(cards)));
    });
  });

  test('sortedByDueDate property keeps equal due dates in their order', () {
    forAll(
      (random) {
        final moment = generatedUtcMoment(random);
        final count = integerBetween(random, 1, 8);
        final cards = <Flashcard>[];

        for (var id = 1; id <= count; id++) {
          cards.add(
            Flashcard(
              id: id,
              face: const BasicFace(front: 'front', back: 'back'),
              nextReview: random.nextBool() ? null : moment,
              schedulingState: null,
            ),
          );
        }

        return cards;
      },
      (cards) {
        final sorted = sortedByDueDate(cards);
        final newIds = <int>[];
        final scheduledIds = <int>[];

        for (final card in cards) {
          if (card.nextReview == null) {
            newIds.add(card.id);
          } else {
            scheduledIds.add(card.id);
          }
        }

        expect(idsOf(sorted), [...newIds, ...scheduledIds]);
      },
    );
  });

  test('isSameUtcDay property matches the UTC calendar day', () {
    forAll(
      (random) => (
        generatedUtcMoment(random),
        Duration(minutes: integerBetween(random, -3000, 3000)),
      ),
      (example) {
        final (moment, shift) = example;
        final shifted = moment.add(shift);
        final isSameDay =
            moment.year == shifted.year &&
            moment.month == shifted.month &&
            moment.day == shifted.day;

        expect(isSameUtcDay(moment, shifted), isSameDay);
        expect(isSameUtcDay(moment.toLocal(), shifted), isSameDay);
      },
    );
  });
}
