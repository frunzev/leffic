import 'dart:math';

import 'package:leffic/shared/api/json_reading.dart';

import '../../support/backend_fakes.dart';
import '../../support/property.dart';

const List<String> unitWireNames = [
  'folder',
  'flashcard_deck',
  'test',
  'note',
  'file',
];

String pythonTimestamp(DateTime moment) {
  return moment.toIso8601String().replaceFirst('T', ' ');
}

DateTime generatedMoment(Random random) {
  return DateTime(
    integerBetween(random, 2020, 2026),
    integerBetween(random, 1, 12),
    integerBetween(random, 1, 28),
    integerBetween(random, 0, 23),
    integerBetween(random, 0, 59),
    integerBetween(random, 0, 59),
    integerBetween(random, 0, 999),
    integerBetween(random, 0, 999),
  );
}

JsonObject _generatedStudyJson(Random random, String countKey) {
  final count = integerBetween(random, 0, 60);

  return {countKey: count, 'due_count': integerBetween(random, 0, count)};
}

JsonObject _generatedFileJson(Random random) {
  final hasStoredFile = random.nextBool();

  return {
    'extension': oneOf(random, ['pdf', 'docx', 'txt']),
    'size_bytes': hasStoredFile ? integerBetween(random, 0, 90000000) : null,
  };
}

JsonObject generatedDetailsJson(Random random, String type) {
  return switch (type) {
    'folder' => {
      'item_count': integerBetween(random, 0, 40),
      'edited_at': pythonTimestamp(generatedMoment(random)),
    },
    'flashcard_deck' => _generatedStudyJson(random, 'card_count'),
    'test' => _generatedStudyJson(random, 'question_count'),
    'note' => {'reading_minutes': integerBetween(random, 1, 45)},
    'file' => _generatedFileJson(random),
    _ => throw ArgumentError.value(type, 'type', 'is not a unit type'),
  };
}

JsonObject unitJsonOfType(
  Random random, {
  required String id,
  required String type,
}) {
  return {
    'id': id,
    'name': wordOf(random),
    'type': type,
    'created_at': pythonTimestamp(generatedMoment(random)),
    ...generatedDetailsJson(random, type),
  };
}

JsonObject generatedUnitJson(Random random, String id) {
  return unitJsonOfType(random, id: id, type: oneOf(random, unitWireNames));
}

List<JsonObject> generatedAncestorJsons(Random random) {
  final count = integerBetween(random, 0, 4);
  final ancestors = <JsonObject>[];

  for (var index = 0; index < count; index++) {
    ancestors.add({
      'id': 'ancestor-$index',
      'name': 'Ancestor ${wordOf(random, maximum: 8)}',
    });
  }

  return ancestors;
}

List<JsonObject> generatedUnitJsons(Random random) {
  final count = integerBetween(random, 1, 8);
  final units = <JsonObject>[];

  for (var index = 0; index < count; index++) {
    units.add(generatedUnitJson(random, 'unit-$index'));
  }

  return units;
}

JsonObject generatedListingJson(Random random) {
  return {
    'parent_folder_name': wordOf(random),
    'content': generatedUnitJsons(random),
    'ancestors': generatedAncestorJsons(random),
  };
}

Map<String, ReplyToRequest> folderReplies(JsonObject listing) {
  return {
    '/access-folder/': answerWith(listing),
    '/flashcards-stats': answerWith({'due': 3, 'done': 1}),
    '/test-items-stats': answerWith({'total': 5, 'correct': 2}),
    '/notes-stats': answerWith({'due': 1, 'read': 0}),
  };
}
