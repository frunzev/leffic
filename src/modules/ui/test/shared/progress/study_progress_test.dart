import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/progress/study_progress.dart';

import '../../support/property.dart';

void main() {
  test('computeCompletedShare property is zero while nothing is planned', () {
    forAll((random) => integerBetween(random, 0, 500), (done) {
      expect(computeCompletedShare(done: done, total: 0), 0);
    });
  });

  test('computeCompletedShare property is the done ratio capped at one', () {
    forAll(
      (random) =>
          (integerBetween(random, 0, 500), integerBetween(random, 1, 500)),
      (counts) {
        final (done, total) = counts;
        final share = computeCompletedShare(done: done, total: total);

        expect(share, lessThanOrEqualTo(1));
        expect(share, done >= total ? 1 : done / total);
      },
    );
  });

  test('countRemaining property never drops below zero', () {
    forAll(
      (random) =>
          (integerBetween(random, 0, 500), integerBetween(random, 0, 500)),
      (counts) {
        final (done, total) = counts;
        final remaining = countRemaining(done: done, total: total);

        expect(remaining, greaterThanOrEqualTo(0));
        expect(remaining, done >= total ? 0 : total - done);
      },
    );
  });
}
