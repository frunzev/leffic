import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/folders/unit_details.dart';

import '../../support/property.dart';
import 'folder_fakes.dart';

void main() {
  test('FolderDetails.fromJson property keeps the count and the edit', () {
    forAll((random) => generatedDetailsJson(random, 'folder'), (json) {
      final details = FolderDetails.fromJson(json);

      expect(details.itemCount, json['item_count']);
      expect(details.editedAt, DateTime.parse(json['edited_at']! as String));
    });
  });

  test('DeckDetails.fromJson property keeps the cards and the due ones', () {
    forAll((random) => generatedDetailsJson(random, 'flashcard_deck'), (json) {
      final details = DeckDetails.fromJson(json);

      expect(details.cardCount, json['card_count']);
      expect(details.dueCount, json['due_count']);
    });
  });

  test('TestDetails.fromJson property keeps the questions and due ones', () {
    forAll((random) => generatedDetailsJson(random, 'test'), (json) {
      final details = TestDetails.fromJson(json);

      expect(details.questionCount, json['question_count']);
      expect(details.dueCount, json['due_count']);
    });
  });

  test('NoteDetails.fromJson property keeps the reading minutes', () {
    forAll((random) => generatedDetailsJson(random, 'note'), (json) {
      expect(
        NoteDetails.fromJson(json).readingMinutes,
        json['reading_minutes'],
      );
    });
  });

  test('FileDetails.fromJson property keeps the size or knows none', () {
    forAll((random) => generatedDetailsJson(random, 'file'), (json) {
      expect(FileDetails.fromJson(json).sizeBytes, json['size_bytes']);
    });
  });

  test('UnitDetails readers property fail fast on a missing count', () {
    final readers = <String, UnitDetails Function(Map<String, Object?>)>{
      'item_count': FolderDetails.fromJson,
      'card_count': DeckDetails.fromJson,
      'question_count': TestDetails.fromJson,
      'reading_minutes': NoteDetails.fromJson,
    };
    final typeOfKey = {
      'item_count': 'folder',
      'card_count': 'flashcard_deck',
      'question_count': 'test',
      'reading_minutes': 'note',
    };

    forAll((random) => oneOf(random, readers.keys.toList()), (key) {
      final type = typeOfKey[key]!;
      final json = Map<String, Object?>.of(
        generatedDetailsJson(Random(fixedSeed), type),
      )..remove(key);

      expect(() => readers[key]!(json), throwsFormatException);
    });
  });

  test('FileDetails.fromJson property refuses a size that is not whole', () {
    forAll((random) => '${integerBetween(random, 0, 9000)} bytes', (text) {
      expect(
        () => FileDetails.fromJson({'size_bytes': text}),
        throwsFormatException,
      );
    });
  });
}
