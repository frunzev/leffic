import 'dart:math';

import 'package:leffic/features/assessment/assessment_models.dart';
import 'package:leffic/shared/api/json_reading.dart';

import '../../support/property.dart';

const List<String> _itemTypes = [
  'multiple_choice',
  'true_or_false',
  'short_answer',
];

String generatedQuestion(Random random) {
  final count = integerBetween(random, 2, 6);
  final words = <String>[];

  for (var index = 0; index < count; index++) {
    words.add(wordOf(random));
  }

  return '${words.join(' ')}?';
}

List<JsonObject> generatedOptionsJson(Random random, String type) {
  final count = switch (type) {
    'short_answer' => 0,
    'true_or_false' => 2,
    _ => integerBetween(random, 2, 5),
  };
  final ids = List<int>.generate(count, (index) => index)..shuffle(random);
  final options = <JsonObject>[];

  for (final id in ids) {
    options.add({'id': id, 'option': 'Option ${wordOf(random)}'});
  }

  return options;
}

List<Object> generatedLastAnswers(Random random, String type) {
  if (random.nextBool()) {
    return const [];
  }

  if (type == 'short_answer') {
    return [wordOf(random)];
  }

  return [integerBetween(random, 0, 1)];
}

JsonObject generatedItemJson(Random random, int id) {
  final type = oneOf(random, _itemTypes);
  final lastAnswers = generatedLastAnswers(random, type);

  return {
    'id': id,
    'type': type,
    'content': {
      'question': generatedQuestion(random),
      'shuffled_options': generatedOptionsJson(random, type),
    },
    'created_at': '2026-11-01 08:00:00',
    'last_answers': lastAnswers.isEmpty ? null : lastAnswers,
  };
}

JsonObject generatedPageJson(Random random) {
  final perPage = integerBetween(random, 1, 10);
  final pageNumber = integerBetween(random, 1, 4);
  final count = integerBetween(random, 0, perPage);
  final items = <JsonObject>[];

  for (var index = 0; index < count; index++) {
    items.add(generatedItemJson(random, pageNumber * 100 + index));
  }

  return {
    'test_items': items,
    'total_items': (pageNumber - 1) * perPage + count,
    'test_session': 'session-${tokenOf(random)}',
    'page': pageNumber,
    'per_page': perPage,
  };
}

TestItem multipleChoiceItem({
  required int id,
  required int optionCount,
  List<Object> lastAnswers = const [],
}) {
  final options = <JsonObject>[];

  for (var optionId = 0; optionId < optionCount; optionId++) {
    options.add({'id': optionId, 'option': 'Option $id-$optionId'});
  }

  return TestItem.fromJson({
    'id': id,
    'type': 'multiple_choice',
    'content': {'question': 'Question $id?', 'shuffled_options': options},
    'last_answers': lastAnswers.isEmpty ? null : lastAnswers,
  });
}

JsonObject chosenItemsPageJson({
  required int pageNumber,
  required int perPage,
  required List<int> itemIds,
  String testSession = 'session-1',
}) {
  final firstIndex = min(itemIds.length, (pageNumber - 1) * perPage);
  final lastIndex = min(itemIds.length, pageNumber * perPage);
  final items = <JsonObject>[];

  for (final number in itemIds.sublist(firstIndex, lastIndex)) {
    items.add({
      'id': number,
      'type': 'multiple_choice',
      'content': {
        'question': 'Question $number?',
        'shuffled_options': [
          {'id': 1, 'option': 'Wrong $number'},
          {'id': 0, 'option': 'Right $number'},
        ],
      },
      'last_answers': null,
    });
  }

  return {
    'test_items': items,
    'total_items': itemIds.length,
    'test_session': testSession,
    'page': pageNumber,
    'per_page': perPage,
  };
}

JsonObject testPageJson({
  required int pageNumber,
  required int perPage,
  required int totalItems,
  String testSession = 'session-1',
}) {
  return chosenItemsPageJson(
    pageNumber: pageNumber,
    perPage: perPage,
    itemIds: List.generate(totalItems, (index) => index + 1),
    testSession: testSession,
  );
}
