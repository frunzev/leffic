import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/flashcards/face_box.dart';
import 'package:leffic/shared/design/design_colors.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

const Key _contentKey = Key('face content');
const double _faceMinimumHeight = 232;
const double _verticalPadding = 48;

void main() {
  testWidgets('FlashcardFaceBox property is 232 tall at least, centring', (
    tester,
  ) async {
    final examples = examplesOf(
      (random) => (
        oneOf(random, FaceSide.values),
        integerBetween(random, 20, 600).toDouble(),
        integerBetween(random, 10, 300).toDouble(),
      ),
      runs: 16,
    );

    for (final (side, contentWidth, contentHeight) in examples) {
      useDesktopSurface(tester);
      await tester.pumpWidget(
        hostedPlainly(
          Center(
            child: SizedBox(
              width: 718,
              child: FlashcardFaceBox(
                side: side,
                child: SizedBox(
                  key: _contentKey,
                  width: contentWidth,
                  height: contentHeight,
                ),
              ),
            ),
          ),
        ),
      );

      final face = tester.getRect(find.byType(FlashcardFaceBox));
      final content = tester.getRect(find.byKey(_contentKey));
      final topBorder = side == FaceSide.answer ? 1 : 0;
      final expectedHeight = max(
        _faceMinimumHeight,
        contentHeight + 2 * _verticalPadding + topBorder,
      );

      expect(face.height, expectedHeight);
      expect(content.center.dx, face.center.dx);
      expect(content.top - face.top - topBorder, face.bottom - content.bottom);
      expect(content.top - face.top - topBorder, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('FlashcardFaceBox property sets the answer on surface-2', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final side in FaceSide.values) {
      await tester.pumpWidget(
        hostedPlainly(
          FlashcardFaceBox(side: side, child: const SizedBox.shrink()),
        ),
      );

      final decorations = find.descendant(
        of: find.byType(FlashcardFaceBox),
        matching: find.byType(DecoratedBox),
      );

      switch (side) {
        case FaceSide.prompt:
          expect(decorations, findsNothing);
        case FaceSide.answer:
          final decoration =
              tester.widget<DecoratedBox>(decorations).decoration
                  as BoxDecoration;

          expect(decoration.color, colors.surfaceSecondary);
          expect(
            decoration.border,
            Border(top: BorderSide(color: colors.line)),
          );
      }
    }
  });
}
