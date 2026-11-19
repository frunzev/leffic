import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/flashcards/face_views.dart';
import 'package:leffic/features/flashcards/flashcard_faces.dart';
import 'package:leffic/shared/design/design_colors.dart';

import '../../support/property.dart';
import '../../support/rendered_text.dart';
import 'face_test_support.dart';
import 'flashcard_generators.dart';

String _shownText(WidgetTester tester) {
  final buffer = StringBuffer();

  for (final paragraph in tester.widgetList<RichText>(find.byType(RichText))) {
    buffer.writeln(withoutLineBreaks(paragraph.text.toPlainText()));
  }

  return buffer.toString();
}

void main() {
  testWidgets('FlashcardPromptView property shows only the asked side', (
    tester,
  ) async {
    for (final face in examplesOf(generatedFace, runs: 20)) {
      await pumpAtCardWidth(tester, FlashcardPromptView(face: face));

      final shown = _shownText(tester);

      switch (face) {
        case BasicFace(:final front):
          expect(shown, contains(front));
        case ClozeFace(:final hiddenParts):
          for (final hiddenPart in hiddenParts) {
            expect(shown, isNot(contains(hiddenPart)));
          }
        case ListFace(:final question, :final items):
          expect(shown, contains(question));
          expect(
            shown,
            contains('Name ${items.length} items, then check yourself.'),
          );
        case FeynmanFace(:final prompt):
          expect(shown, contains(prompt));
      }
    }
  });

  testWidgets('FlashcardAnswerView property reveals the answer side', (
    tester,
  ) async {
    for (final face in examplesOf(generatedFace, runs: 20)) {
      await pumpAtCardWidth(tester, FlashcardAnswerView(face: face));

      final shown = _shownText(tester);

      switch (face) {
        case BasicFace(:final back):
          expect(shown, contains(back));
        case ClozeFace(:final text):
          expect(reassembledCloze(clozeParagraphOf(tester).text), text);
        case ListFace(:final items):
          for (final item in items) {
            expect(shown, contains(item));
          }
        case FeynmanFace(:final referenceExplanation):
          expect(shown, contains(referenceExplanation));
      }
    }
  });

  testWidgets('FlashcardPromptView property sets it in 24px medium ink', (
    tester,
  ) async {
    for (final face in examplesOf(generatedFace, runs: 20)) {
      await pumpAtCardWidth(tester, FlashcardPromptView(face: face));

      final colors = DesignColors.of(
        tester.element(find.byType(FlashcardPromptView)),
      );
      final style = face is ClozeFace
          ? clozeParagraphOf(tester).text.style!
          : renderedStyleOf(tester, face.question);

      expect(style.fontSize, 24);
      expect(style.fontWeight, FontWeight.w500);
      expect(style.height, 1.35);
      expect(style.color, colors.ink);

      if (face is ListFace) {
        final hint = renderedStyleOf(
          tester,
          'Name ${face.items.length} items, then check yourself.',
        );

        expect(hint.fontSize, 14);
        expect(hint.color, colors.inkTertiary);
      }
    }
  });

  testWidgets('FlashcardAnswerView property sets it in 24px regular ink-2', (
    tester,
  ) async {
    for (final face in examplesOf(generatedFace, runs: 20)) {
      if (face is ListFace) {
        continue;
      }

      await pumpAtCardWidth(tester, FlashcardAnswerView(face: face));

      final colors = DesignColors.of(
        tester.element(find.byType(FlashcardAnswerView)),
      );
      final style = face is ClozeFace
          ? clozeParagraphOf(tester).text.style!
          : renderedStyleOf(tester, face.answer);

      expect(style.fontSize, 24);
      expect(style.fontWeight, FontWeight.w400);
      expect(style.height, 1.35);
      expect(style.color, colors.inkSecondary);
    }
  });

  testWidgets('FlashcardAnswerView property lists items 8px apart, left', (
    tester,
  ) async {
    final faces = examplesOf(
      (random) =>
          ListFace(question: 'q', items: generatedWords(random, minimum: 2)),
      runs: 8,
    );

    for (final face in faces) {
      await pumpAtCardWidth(tester, FlashcardAnswerView(face: face));

      final itemRects = [
        for (final item in face.items) tester.getRect(find.text(item)),
      ];
      final faceRect = tester.getRect(find.byType(FlashcardAnswerView));
      var blockRight = itemRects.first.right;

      for (var index = 0; index < itemRects.length; index++) {
        final style = renderedStyleOf(tester, face.items[index]);

        expect(style.fontSize, 16);
        expect(itemRects[index].left, itemRects.first.left);

        if (index > 0) {
          expect(itemRects[index].top - itemRects[index - 1].bottom, 8);
        }

        if (itemRects[index].right > blockRight) {
          blockRight = itemRects[index].right;
        }
      }

      final blockLeft = itemRects.first.left - 24;

      expect((blockLeft + blockRight) / 2, closeTo(faceRect.center.dx, 0.5));
      expect(find.text('•\u00A0'), findsNWidgets(face.items.length));
    }
  });
}
