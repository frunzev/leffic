import 'dart:math';

import 'package:leffic/features/flashcards/flashcard_faces.dart';
import 'package:leffic/features/flashcards/flashcard_models.dart';
import 'package:leffic/shared/api/json_reading.dart';

import '../../support/property.dart';

typedef FaceContent = (String type, JsonObject content);

const List<String> _flashcardTypes = ['basic', 'cloze', 'list', 'feynman'];

List<String> generatedWords(Random random, {int minimum = 1}) {
  final count = integerBetween(random, minimum, 5);
  final words = <String>[];

  for (var index = 0; index < count; index++) {
    words.add(wordOf(random));
  }

  return words;
}

String generatedSentence(Random random) {
  return generatedWords(random).join(' ');
}

JsonObject _generatedClozeContent(Random random) {
  final words = generatedWords(random);
  final hiddenParts = <String>[];

  for (final word in words) {
    if (random.nextBool()) {
      hiddenParts.add(word);
    }
  }

  return {'text': words.join(' '), 'hidden_parts': hiddenParts};
}

FaceContent generatedFaceContent(Random random) {
  final type = oneOf(random, _flashcardTypes);
  final JsonObject content = switch (type) {
    'basic' => {
      'front': generatedSentence(random),
      'back': generatedSentence(random),
    },
    'cloze' => _generatedClozeContent(random),
    'list' => {
      'question': generatedSentence(random),
      'items': generatedWords(random),
    },
    _ => {
      'prompt': generatedSentence(random),
      'reference_explanation': generatedSentence(random),
    },
  };

  return (type, content);
}

FlashcardFace generatedFace(Random random) {
  final (type, content) = generatedFaceContent(random);

  return FlashcardFace.fromContent(type: type, content: content);
}

DateTime generatedUtcMoment(Random random) {
  return DateTime.utc(
    integerBetween(random, 2020, 2030),
    integerBetween(random, 1, 12),
    integerBetween(random, 1, 28),
    integerBetween(random, 0, 23),
    integerBetween(random, 0, 59),
    integerBetween(random, 0, 59),
  );
}

String serverTimestamp(DateTime moment) {
  final isoText = moment.toUtc().toIso8601String();

  return isoText.substring(0, 19).replaceFirst('T', ' ');
}

JsonObject generatedSchedulingState(Random random) {
  return {
    'card_id': integerBetween(random, 1, 99999),
    'state': integerBetween(random, 1, 3),
    'step': integerBetween(random, 0, 3),
    'due': serverTimestamp(generatedUtcMoment(random)),
  };
}

JsonObject generatedFlashcardJson(Random random, int id) {
  final (type, content) = generatedFaceContent(random);
  final isNew = random.nextBool();

  return {
    'id': id,
    'type': type,
    'next_review': isNew ? null : serverTimestamp(generatedUtcMoment(random)),
    'content': content,
    'created_at': serverTimestamp(generatedUtcMoment(random)),
    'fsrs_card': isNew ? null : generatedSchedulingState(random),
  };
}

JsonObject generatedDueJson(Random random) {
  final count = integerBetween(random, 0, 6);
  final flashcards = <JsonObject>[];

  for (var index = 0; index < count; index++) {
    flashcards.add(generatedFlashcardJson(random, index + 1));
  }

  return {
    'flashcards': flashcards,
    'total_flashcards': count + integerBetween(random, 0, 20),
  };
}

JsonObject generatedIntervalsJson(Random random) {
  return {
    '1': integerBetween(random, 0, 600),
    '2': integerBetween(random, 600, 86400),
    '3': integerBetween(random, 86400, 2592000),
    '4': integerBetween(random, 2592000, 40000000),
  };
}

Flashcard generatedFlashcard(Random random, int id) {
  final isNew = random.nextInt(4) == 0;

  return Flashcard(
    id: id,
    face: BasicFace(front: 'front $id', back: 'back $id'),
    nextReview: isNew ? null : generatedUtcMoment(random),
    schedulingState: null,
  );
}

List<Flashcard> generatedFlashcards(Random random, {int minimum = 1}) {
  final count = integerBetween(random, minimum, 8);
  final cards = <Flashcard>[];

  for (var index = 0; index < count; index++) {
    cards.add(generatedFlashcard(random, index + 1));
  }

  return cards;
}

List<int> idsOf(List<Flashcard> cards) {
  final ids = <int>[];

  for (final card in cards) {
    ids.add(card.id);
  }

  return ids;
}
