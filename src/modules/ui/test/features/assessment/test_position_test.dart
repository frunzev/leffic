import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/assessment/assessment_models.dart';
import 'package:leffic/features/assessment/test_position.dart';

import '../../support/property.dart';
import 'assessment_generators.dart';

void main() {
  test('TestPosition.fromJson property round-trips toJson', () {
    forAll(
      (random) => TestPosition(
        pageNumber: integerBetween(random, 1, 50),
        itemIndex: integerBetween(random, 0, 50),
      ),
      (position) {
        final restored = TestPosition.fromJson(position.toJson());

        expect(restored.pageNumber, position.pageNumber);
        expect(restored.itemIndex, position.itemIndex);
      },
    );
  });

  test('TestPosition.fromJson property refuses impossible positions', () {
    forAll(
      (random) => oneOf(random, [
        {'page': integerBetween(random, -5, 0), 'index': 0},
        {'page': 1, 'index': integerBetween(random, -5, -1)},
        {'page': 1},
      ]),
      (json) {
        expect(() => TestPosition.fromJson(json), throwsFormatException);
      },
    );
  });

  test('overallPosition property counts every item of earlier pages', () {
    forAll(
      (random) {
        final pageJson = testPageJson(
          pageNumber: integerBetween(random, 1, 5),
          perPage: integerBetween(random, 1, 10),
          totalItems: 60,
        );
        final page = TestItemsPage.fromJson(pageJson);

        return (page, integerBetween(random, 0, page.items.length - 1));
      },
      (example) {
        final (page, itemIndex) = example;
        final position = overallPosition(page, itemIndex);

        expect(position, (page.pageNumber - 1) * page.perPage + itemIndex + 1);
        expect(position, page.items[itemIndex].id);
        expect(position, inInclusiveRange(1, page.totalItems));
      },
    );
  });
}
