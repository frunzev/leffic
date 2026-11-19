import '../../shared/api/json_reading.dart';
import 'test_answer.dart';

enum TestItemKind {
  multipleChoice('multiple_choice'),
  trueOrFalse('true_or_false'),
  shortAnswer('short_answer');

  const TestItemKind(this.wireName);

  final String wireName;

  static TestItemKind fromWireName(String wireName) {
    for (final kind in values) {
      if (kind.wireName == wireName) {
        return kind;
      }
    }

    throw FormatException('Unknown test item type "$wireName"');
  }
}

class TestOption {
  const TestOption({required this.id, required this.text});

  factory TestOption.fromJson(JsonObject json) {
    return TestOption(
      id: readWholeNumber(json, 'id'),
      text: readTextOr(json, 'option', ''),
    );
  }

  final int id;
  final String text;
}

class TestItem {
  const TestItem({
    required this.id,
    required this.kind,
    required this.question,
    required this.options,
    required this.lastAnswers,
  });

  factory TestItem.fromJson(JsonObject json) {
    final content = readObject(json, 'content');
    final options = <TestOption>[];

    for (final entry in readObjects(content, 'shuffled_options')) {
      options.add(TestOption.fromJson(entry));
    }

    return TestItem(
      id: readWholeNumber(json, 'id'),
      kind: TestItemKind.fromWireName(readText(json, 'type')),
      question: readTextOr(content, 'question', ''),
      options: options,
      lastAnswers: readTestAnswers(json, 'last_answers'),
    );
  }

  final int id;
  final TestItemKind kind;
  final String question;
  final List<TestOption> options;
  final List<TestAnswer> lastAnswers;

  bool get isEditable => kind == TestItemKind.multipleChoice;
}

class TestItemsPage {
  const TestItemsPage({
    required this.testSession,
    required this.items,
    required this.pageNumber,
    required this.perPage,
    required this.totalItems,
  });

  factory TestItemsPage.fromJson(JsonObject json) {
    final items = <TestItem>[];

    for (final entry in readObjects(json, 'test_items')) {
      items.add(TestItem.fromJson(entry));
    }

    return TestItemsPage(
      testSession: readText(json, 'test_session'),
      items: items,
      pageNumber: readWholeNumber(json, 'page'),
      perPage: readWholeNumber(json, 'per_page'),
      totalItems: readWholeNumber(json, 'total_items'),
    );
  }

  final String testSession;
  final List<TestItem> items;
  final int pageNumber;
  final int perPage;
  final int totalItems;
}

class TestSessionResult {
  const TestSessionResult({
    required this.correctCount,
    required this.missedItemIds,
  });

  factory TestSessionResult.fromJson(JsonObject json) {
    return TestSessionResult(
      correctCount: readWholeNumber(json, 'correct'),
      missedItemIds: readWholeNumbers(json, 'missed_item_ids'),
    );
  }

  static const TestSessionResult nothingAnswered = TestSessionResult(
    correctCount: 0,
    missedItemIds: [],
  );

  final int correctCount;
  final List<int> missedItemIds;
}
