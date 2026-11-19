import '../../shared/api/json_reading.dart';
import 'assessment_models.dart';

const int firstPageNumber = 1;
const int _firstItemIndex = 0;

class TestPosition {
  const TestPosition({required this.pageNumber, required this.itemIndex});

  factory TestPosition.fromJson(JsonObject json) {
    final pageNumber = readWholeNumber(json, 'page');
    final itemIndex = readWholeNumber(json, 'index');

    if (pageNumber < firstPageNumber || itemIndex < _firstItemIndex) {
      throw FormatException('No test has page $pageNumber, item $itemIndex');
    }

    return TestPosition(pageNumber: pageNumber, itemIndex: itemIndex);
  }

  static const TestPosition start = TestPosition(
    pageNumber: firstPageNumber,
    itemIndex: _firstItemIndex,
  );

  final int pageNumber;
  final int itemIndex;

  JsonObject toJson() => {'page': pageNumber, 'index': itemIndex};
}

int overallPosition(TestItemsPage page, int itemIndex) {
  final itemsOnEarlierPages =
      (page.pageNumber - firstPageNumber) * page.perPage;

  return itemsOnEarlierPages + itemIndex + 1;
}
