import 'dart:math';

import '../../shared/progress/study_progress.dart';
import 'flashcard_faces.dart';
import 'flashcard_models.dart';

class ReviewQueue {
  const ReviewQueue({
    required this.cards,
    required this.totalToReview,
    required this.reviewedCount,
  });

  factory ReviewQueue.startingWith(DueFlashcards due) {
    return ReviewQueue(
      cards: due.cards,
      totalToReview: due.totalCount,
      reviewedCount: 0,
    );
  }

  final List<Flashcard> cards;
  final int totalToReview;
  final int reviewedCount;

  Flashcard? get current {
    if (cards.isEmpty) {
      return null;
    }

    return cards.first;
  }

  int get leftCount =>
      countRemaining(done: reviewedCount, total: totalToReview);

  double get completedShare {
    return computeCompletedShare(done: reviewedCount, total: totalToReview);
  }

  ReviewQueue refilledWith(DueFlashcards due) {
    final knownTotal = totalToReview == 0 ? due.totalCount : totalToReview;

    return ReviewQueue(
      cards: due.cards,
      totalToReview: knownTotal,
      reviewedCount: reviewedCount,
    );
  }

  ReviewQueue afterReview(ReviewOutcome outcome, {required DateTime now}) {
    final rescheduled = [cards.first.rescheduled(outcome), ...cards.skip(1)];
    final isDueAfterTheRest = _isDueNoEarlierThanLast(
      rescheduled,
      outcome.dueDate,
    );
    final remaining = isDueAfterTheRest
        ? rescheduled.sublist(1)
        : sortedByDueDate(rescheduled);
    final isDueToday = isSameUtcDay(outcome.dueDate, now);

    return ReviewQueue(
      cards: remaining,
      totalToReview: totalToReview,
      reviewedCount: isDueToday ? reviewedCount : reviewedCount + 1,
    );
  }

  ReviewQueue afterDeletion() {
    return ReviewQueue(
      cards: cards.sublist(1),
      totalToReview: max(0, totalToReview - 1),
      reviewedCount: reviewedCount,
    );
  }

  ReviewQueue withCurrentFace(FlashcardFace face) {
    return ReviewQueue(
      cards: [cards.first.withFace(face), ...cards.skip(1)],
      totalToReview: totalToReview,
      reviewedCount: reviewedCount,
    );
  }
}

bool _isDueNoEarlierThanLast(List<Flashcard> cards, DateTime dueDate) {
  final lastReview = cards.last.nextReview;

  if (lastReview == null) {
    return true;
  }

  return !dueDate.isBefore(lastReview);
}

bool isSameUtcDay(DateTime first, DateTime second) {
  final firstUtc = first.toUtc();
  final secondUtc = second.toUtc();

  return firstUtc.year == secondUtc.year &&
      firstUtc.month == secondUtc.month &&
      firstUtc.day == secondUtc.day;
}

List<Flashcard> sortedByDueDate(List<Flashcard> cards) {
  final positions = List<int>.generate(cards.length, (index) => index);

  positions.sort((left, right) {
    final dueOrder = _compareDueDates(
      cards[left].nextReview,
      cards[right].nextReview,
    );

    if (dueOrder != 0) {
      return dueOrder;
    }

    return left.compareTo(right);
  });

  final sorted = <Flashcard>[];

  for (final position in positions) {
    sorted.add(cards[position]);
  }

  return sorted;
}

int _compareDueDates(DateTime? left, DateTime? right) {
  if (left == null && right == null) {
    return 0;
  }

  if (left == null) {
    return -1;
  }

  if (right == null) {
    return 1;
  }

  return left.compareTo(right);
}
