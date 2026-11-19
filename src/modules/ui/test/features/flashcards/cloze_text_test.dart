import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/flashcards/cloze_pieces.dart';
import 'package:leffic/features/flashcards/cloze_text.dart';
import 'package:leffic/features/flashcards/flashcard_faces.dart';
import 'package:leffic/shared/design/design_colors.dart';

import '../../support/property.dart';
import 'face_test_support.dart';
import 'flashcard_generators.dart';

const String _blankCharacter = '\u00A0';

void main() {
  testWidgets('ClozeText property puts each hidden part in a mark in place', (
    tester,
  ) async {
    final examples = examplesOf(
      (random) => (generatedFace(random), oneOf(random, ClozeMarkLook.values)),
      runs: 30,
    );

    for (final (face, look) in examples) {
      if (face is! ClozeFace) {
        continue;
      }

      await pumpAtCardWidth(
        tester,
        ClozeText(
          text: face.text,
          hiddenParts: face.hiddenParts,
          look: look,
          style: const TextStyle(fontSize: 24),
        ),
      );

      final pieces = clozePieces(
        text: face.text,
        hiddenParts: face.hiddenParts,
      );
      final hiddenPieces = pieces.where((piece) => piece.isHidden).toList();
      final marks = tester.widgetList<ClozeMark>(find.byType(ClozeMark));

      expect(reassembledCloze(clozeParagraphOf(tester).text), face.text);
      expect(clozeParagraphOf(tester).textAlign, TextAlign.center);
      expect(
        marks.map((mark) => mark.hiddenPart),
        hiddenPieces.map((piece) => piece.text),
      );
      expect(marks.every((mark) => mark.look == look), isTrue);
    }
  });

  testWidgets('ClozeMark property blanks in surface-3 and reveals in brand', (
    tester,
  ) async {
    final examples = examplesOf(
      (random) => (wordOf(random), oneOf(random, ClozeMarkLook.values)),
      runs: 12,
    );

    for (final (hiddenPart, look) in examples) {
      await pumpAtCardWidth(
        tester,
        Center(
          child: ClozeMark(
            hiddenPart: hiddenPart,
            look: look,
            textStyle: const TextStyle(fontSize: 24),
          ),
        ),
      );

      final colors = DesignColors.of(tester.element(find.byType(ClozeMark)));
      final markText = tester.widget<Text>(
        find.descendant(
          of: find.byType(ClozeMark),
          matching: find.byType(Text),
        ),
      );
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.byType(ClozeMark),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      final clip = tester.widget<ClipRRect>(
        find.descendant(
          of: find.byType(ClozeMark),
          matching: find.byType(ClipRRect),
        ),
      );

      expect(clip.borderRadius, BorderRadius.circular(6));
      expect(markText.style?.height, kTextHeightNone);

      switch (look) {
        case ClozeMarkLook.blank:
          expect(markText.data, _blankCharacter * hiddenPart.length);
          expect(markText.style?.color, const Color(0x00000000));
          expect(decoration.color, colors.surfaceTertiary);
          expect(
            (decoration.border! as Border).bottom,
            BorderSide(color: colors.lineHover, width: 2),
          );
        case ClozeMarkLook.revealed:
          expect(markText.data, hiddenPart);
          expect(markText.style?.color, colors.brandStrong);
          expect(decoration.color, colors.brandSurface);
          expect(decoration.border, isNull);
      }
    }
  });
}
