import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/folders/due_models.dart';

import '../../support/property.dart';

StudyCount _generatedCount(Random random) {
  return StudyCount(
    due: integerBetween(random, 0, 300),
    done: integerBetween(random, 0, 300),
  );
}

DueSummary _generatedSummary(Random random) {
  return DueSummary(
    flashcards: _generatedCount(random),
    testItems: _generatedCount(random),
    notes: _generatedCount(random),
  );
}

void main() {
  test('StudyCount.fromFlashcardsJson property reads due and done', () {
    forAll(
      (random) =>
          (integerBetween(random, 0, 900), integerBetween(random, 0, 900)),
      (example) {
        final (due, done) = example;
        final count = StudyCount.fromFlashcardsJson({'due': due, 'done': done});

        expect(count.due, due);
        expect(count.done, done);
      },
    );
  });

  test('StudyCount.fromTestItemsJson property never reports negative due', () {
    forAll(
      (random) =>
          (integerBetween(random, 0, 900), integerBetween(random, 0, 900)),
      (example) {
        final (total, correct) = example;
        final count = StudyCount.fromTestItemsJson({
          'total': total,
          'correct': correct,
        });

        expect(count.due, greaterThanOrEqualTo(0));
        expect(count.done, correct);
        expect(count.due, max(0, total - correct));
      },
    );
  });

  test('StudyCount.fromNotesJson property counts read notes as done', () {
    forAll(
      (random) =>
          (integerBetween(random, 0, 900), integerBetween(random, 0, 900)),
      (example) {
        final (due, read) = example;
        final count = StudyCount.fromNotesJson({'due': due, 'read': read});

        expect(count.due, due);
        expect(count.done, read);
      },
    );
  });

  test('StudyCount property parsing fails fast on missing numbers', () {
    forAll((random) => oneOf(random, ['due', 'done']), (missingKey) {
      final json = {'due': 1, 'done': 2}..remove(missingKey);

      expect(() => StudyCount.fromFlashcardsJson(json), throwsFormatException);
    });
  });

  test('DueSummary property totals add up and the share stays in 0..1', () {
    forAll(_generatedSummary, (summary) {
      final parts = [summary.flashcards, summary.testItems, summary.notes];
      final dueSum = parts.fold(0, (total, part) => total + part.due);
      final doneSum = parts.fold(0, (total, part) => total + part.done);

      expect(summary.dueCount, dueSum);
      expect(summary.doneCount, doneSum);
      expect(summary.totalCount, dueSum + doneSum);
      expect(summary.completedShare, inInclusiveRange(0, 1));
    });
  });

  test('DueSummary property reviews the flashcards and test items due', () {
    forAll(_generatedSummary, (summary) {
      final reviewable = summary.flashcards.due + summary.testItems.due;

      expect(summary.reviewableCount, reviewable);
      expect(summary.reviewableCount, lessThanOrEqualTo(summary.dueCount));
    });
  });

  test('DueSummary property shares 0 with nothing done, 1 with all done', () {
    forAll((random) => integerBetween(random, 1, 300), (count) {
      final nothingDone = DueSummary(
        flashcards: StudyCount(due: count, done: 0),
        testItems: StudyCount.nothing,
        notes: StudyCount.nothing,
      );
      final allDone = DueSummary(
        flashcards: StudyCount.nothing,
        testItems: StudyCount(due: 0, done: count),
        notes: StudyCount.nothing,
      );

      expect(nothingDone.completedShare, 0);
      expect(allDone.completedShare, 1);
    });
  });
}
