import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/flashcards/face_editing.dart';

import '../../support/property.dart';
import 'flashcard_generators.dart';

void main() {
  test('faceEditedWith property rebuilds the face from its own fields', () {
    forAll(generatedFace, (face) {
      final fields = editableFieldsOf(face);
      final rebuilt = faceEditedWith(
        face,
        firstText: fields.firstText,
        secondText: fields.secondText,
      );

      expect(rebuilt.toContent(), face.toContent());
      expect(rebuilt.runtimeType, face.runtimeType);
    });
  });

  test('faceEditedWith property keeps the kind for any typed text', () {
    forAll(
      (random) => (generatedFace(random), anyTextOf(random), anyTextOf(random)),
      (example) {
        final (face, firstText, secondText) = example;
        final edited = faceEditedWith(
          face,
          firstText: firstText,
          secondText: secondText,
        );

        expect(edited.runtimeType, face.runtimeType);
        expect(edited.question, firstText);
      },
    );
  });

  test('editableFieldsOf property labels both fields', () {
    forAll(generatedFace, (face) {
      final fields = editableFieldsOf(face);

      expect(fields.firstLabel, isNotEmpty);
      expect(fields.secondLabel, isNotEmpty);
      expect(fields.firstLabel, isNot(fields.secondLabel));
    });
  });

  test('nonBlankLines property keeps trimmed lines in their order', () {
    forAll((random) => textFrom(random, 'ab \n', 0, 40), (text) {
      final lines = nonBlankLines(text);
      final expected = <String>[];

      for (final line in text.split('\n')) {
        if (line.trim().isNotEmpty) {
          expected.add(line.trim());
        }
      }

      expect(lines, expected);
    });
  });
}
