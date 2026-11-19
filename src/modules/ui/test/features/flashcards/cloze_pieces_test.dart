import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/flashcards/cloze_pieces.dart';

import '../../support/property.dart';

typedef _ClozeExample = (String text, List<String> hiddenParts);

const String _smallAlphabet = 'abc ';

_ClozeExample _generatedCloze(Random random) {
  final text = textFrom(random, _smallAlphabet, 0, 30);
  final count = integerBetween(random, 0, 4);
  final hiddenParts = <String>[];

  for (var index = 0; index < count; index++) {
    hiddenParts.add(textFrom(random, _smallAlphabet, 0, 3));
  }

  return (text, hiddenParts);
}

void main() {
  test('clozePieces property joins back into the whole sentence', () {
    forAll(_generatedCloze, (example) {
      final (text, hiddenParts) = example;
      final buffer = StringBuffer();

      for (final piece in clozePieces(text: text, hiddenParts: hiddenParts)) {
        buffer.write(piece.text);
      }

      expect(buffer.toString(), text);
    });
  });

  test('clozePieces property hides only the given parts', () {
    forAll(_generatedCloze, (example) {
      final (text, hiddenParts) = example;

      for (final piece in clozePieces(text: text, hiddenParts: hiddenParts)) {
        expect(piece.text, isNotEmpty);

        if (piece.isHidden) {
          expect(hiddenParts, contains(piece.text));
        }
      }
    });
  });

  test('clozePieces property leaves no hidden part in sight', () {
    forAll(_generatedCloze, (example) {
      final (text, hiddenParts) = example;
      final visibleText = StringBuffer();

      for (final piece in clozePieces(text: text, hiddenParts: hiddenParts)) {
        visibleText.write(piece.isHidden ? '|' : piece.text);
      }

      for (final hiddenPart in hiddenParts) {
        if (hiddenPart.isNotEmpty) {
          expect(visibleText.toString(), isNot(contains(hiddenPart)));
        }
      }
    });
  });
}
