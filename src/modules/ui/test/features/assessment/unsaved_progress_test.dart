import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/assessment/test_position.dart';
import 'package:leffic/features/assessment/unsaved_progress.dart';

import '../../support/property.dart';

void main() {
  test('UnsavedProgress property always recalls the first question', () async {
    for (final (pageNumber, itemIndex) in examplesOf(
      (random) => (integerBetween(random, 1, 9), integerBetween(random, 0, 9)),
    )) {
      const memory = UnsavedProgress();

      await memory.remember(
        TestPosition(pageNumber: pageNumber, itemIndex: itemIndex),
      );
      final recalled = await memory.recall();

      expect(recalled.pageNumber, TestPosition.start.pageNumber);
      expect(recalled.itemIndex, TestPosition.start.itemIndex);

      await memory.forget();

      expect((await memory.recall()).pageNumber, firstPageNumber);
    }
  });
}
