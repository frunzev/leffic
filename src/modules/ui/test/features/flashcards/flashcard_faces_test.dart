import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/flashcards/flashcard_faces.dart';

import '../../support/property.dart';
import 'flashcard_generators.dart';

const List<String> _sideChoices = ['', '  ', 'word', ' padded '];

void main() {
  test('FlashcardFace.fromContent property round-trips toContent', () {
    forAll(generatedFaceContent, (example) {
      final (type, content) = example;
      final face = FlashcardFace.fromContent(type: type, content: content);

      expect(face.toContent(), content);
    });
  });

  test('FlashcardFace.fromContent property refuses an unknown type', () {
    forAll((random) => (wordOf(random), generatedFaceContent(random)), (
      example,
    ) {
      final (unknownWord, (_, content)) = example;

      expect(
        () => FlashcardFace.fromContent(
          type: 'unknown-$unknownWord',
          content: content,
        ),
        throwsFormatException,
      );
    });
  });

  test('FlashcardFace.fromContent property fails fast without a field', () {
    forAll(
      (random) {
        final (type, content) = generatedFaceContent(random);
        final missingKey = oneOf(random, content.keys.toList());

        return (type, content, missingKey);
      },
      (example) {
        final (type, content, missingKey) = example;
        final broken = Map.of(content)..remove(missingKey);

        expect(
          () => FlashcardFace.fromContent(type: type, content: broken),
          throwsFormatException,
        );
      },
    );
  });

  test('FlashcardFace property words the asked side and its answer', () {
    forAll(generatedFace, (face) {
      switch (face) {
        case BasicFace(:final front, :final back):
          expect((face.question, face.answer), (front, back));
        case ClozeFace(:final text, :final hiddenParts):
          expect(face.question, text);
          expect(face.answer, endsWith(hiddenParts.join(', ')));
        case ListFace(:final question, :final items):
          expect(face.question, question);
          expect(face.answer.split(', '), items);
        case FeynmanFace(:final prompt, :final referenceExplanation):
          expect((face.question, face.answer), (prompt, referenceExplanation));
      }
    });
  });

  test('FlashcardFace.isIncomplete property is true when a side is blank', () {
    forAll(
      (random) => (oneOf(random, _sideChoices), oneOf(random, _sideChoices)),
      (example) {
        final (first, second) = example;
        final isBlank = first.trim().isEmpty || second.trim().isEmpty;
        final faces = [
          BasicFace(front: first, back: second),
          FeynmanFace(prompt: first, referenceExplanation: second),
          ListFace(question: first, items: [if (second.isNotEmpty) second]),
        ];

        for (final face in faces) {
          expect(face.isIncomplete, isBlank);
        }
      },
    );
  });

  test('ClozeFace.isIncomplete property only needs the sentence', () {
    forAll((random) => (oneOf(random, _sideChoices), generatedWords(random)), (
      example,
    ) {
      final (text, hiddenParts) = example;
      final face = ClozeFace(text: text, hiddenParts: hiddenParts);

      expect(face.isIncomplete, text.trim().isEmpty);
    });
  });
}
