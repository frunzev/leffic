import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/assessment/assessment_models.dart';
import 'package:leffic/shared/api/json_reading.dart';

import '../../support/property.dart';
import 'assessment_generators.dart';

void main() {
  test('TestItemKind.fromWireName property finds every kind', () {
    forAll((random) => oneOf(random, TestItemKind.values), (kind) {
      expect(TestItemKind.fromWireName(kind.wireName), kind);
    });
  });

  test('TestItemKind.fromWireName property refuses unknown kinds', () {
    forAll(wordOf, (word) {
      expect(
        () => TestItemKind.fromWireName('unknown_$word'),
        throwsFormatException,
      );
    });
  });

  test('TestOption.fromJson property reads the id and the text', () {
    forAll((random) => (integerBetween(random, 0, 9), anyTextOf(random)), (
      example,
    ) {
      final (id, text) = example;
      final option = TestOption.fromJson({'id': id, 'option': text});

      expect((option.id, option.text), (id, text));
    });
  });

  test('TestOption.fromJson property reads a missing text as empty', () {
    forAll((random) => integerBetween(random, 0, 9), (id) {
      expect(TestOption.fromJson({'id': id, 'option': null}).text, '');
    });
  });

  test('TestItem.fromJson property reads the item and its options', () {
    forAll((random) => generatedItemJson(random, random.nextInt(999)), (json) {
      final item = TestItem.fromJson(json);
      final content = readObject(json, 'content');
      final optionsJson = readObjects(content, 'shuffled_options');
      final lastAnswers = json['last_answers'] as List<Object?>?;

      expect(item.id, json['id']);
      expect(item.kind.wireName, json['type']);
      expect(item.question, content['question']);
      expect(item.options.length, optionsJson.length);
      expect(item.lastAnswers.length, lastAnswers?.length ?? 0);

      for (var index = 0; index < optionsJson.length; index++) {
        expect(item.options[index].id, optionsJson[index]['id']);
      }
    });
  });

  test('TestItem.isEditable property holds only for multiple choice', () {
    forAll((random) => generatedItemJson(random, 1), (json) {
      final item = TestItem.fromJson(json);

      expect(item.isEditable, item.kind == TestItemKind.multipleChoice);
    });
  });

  test('TestItem.fromJson property fails fast without content', () {
    forAll((random) => generatedItemJson(random, 1), (json) {
      final broken = Map.of(json)..remove('content');

      expect(() => TestItem.fromJson(broken), throwsFormatException);
    });
  });

  test('TestItemsPage.fromJson property reads the page and its session', () {
    forAll(generatedPageJson, (json) {
      final page = TestItemsPage.fromJson(json);

      expect(page.testSession, json['test_session']);
      expect(page.pageNumber, json['page']);
      expect(page.perPage, json['per_page']);
      expect(page.totalItems, json['total_items']);
      expect(page.items.length, readObjects(json, 'test_items').length);
    });
  });

  test('TestItemsPage.fromJson property fails fast without a session', () {
    forAll(generatedPageJson, (json) {
      final broken = Map.of(json)..remove('test_session');

      expect(() => TestItemsPage.fromJson(broken), throwsFormatException);
    });
  });

  test(
    'TestSessionResult.fromJson property reads the score and the missed',
    () {
      forAll(
        (random) => (
          integerBetween(random, 0, 60),
          List.generate(
            integerBetween(random, 0, 6),
            (index) => integerBetween(random, 1, 9999),
          ),
        ),
        (example) {
          final (correct, missedItemIds) = example;
          final result = TestSessionResult.fromJson({
            'correct': correct,
            'missed_item_ids': missedItemIds,
          });

          expect(result.correctCount, correct);
          expect(result.missedItemIds, missedItemIds);
          expect(
            () => TestSessionResult.fromJson({'correct': correct}),
            throwsFormatException,
          );
        },
      );
    },
  );

  test('TestSessionResult.nothingAnswered property has no score or misses', () {
    expect(TestSessionResult.nothingAnswered.correctCount, 0);
    expect(TestSessionResult.nothingAnswered.missedItemIds, isEmpty);
  });
}
