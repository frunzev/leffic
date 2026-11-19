import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/assessment/question_heading.dart';
import 'package:leffic/features/assessment/test_card.dart';
import 'package:leffic/shared/design/card_look.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_shadows.dart';
import 'package:leffic/shared/design/surface_box.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';
import 'assessment_generators.dart';

const Key _contentKey = Key('card content');
const Key _menuKey = Key('card menu');
const double _border = 1;
const double _blockPadding = 32;
const double _inlinePadding = 24;
const double _menuInset = 12;
const double _menuReserve = 52;

typedef _CardExample = ({
  Brightness brightness,
  double width,
  double contentHeight,
  bool hasMenu,
});

void main() {
  testWidgets('TestCard property is the .test-card surface and padding', (
    tester,
  ) async {
    final examples = examplesOf<_CardExample>(
      (random) => (
        brightness: oneOf(random, Brightness.values),
        width: integerBetween(random, 400, 720).toDouble(),
        contentHeight: integerBetween(random, 20, 300).toDouble(),
        hasMenu: random.nextBool(),
      ),
      runs: 10,
    );

    for (final example in examples) {
      await tester.pumpWidget(
        hostedInTheme(
          Center(
            child: SizedBox(
              width: example.width,
              child: TestCard(
                menu: example.hasMenu
                    ? const SizedBox(key: _menuKey, width: 40, height: 40)
                    : null,
                child: SizedBox(
                  key: _contentKey,
                  height: example.contentHeight,
                ),
              ),
            ),
          ),
          brightness: example.brightness,
        ),
      );

      final card = tester.getRect(find.byType(TestCard));
      final content = tester.getRect(find.byKey(_contentKey));
      final surface = tester.widget<SurfaceBox>(find.byType(SurfaceBox));
      final expectedLook = cardLookOf(
        colors: DesignColors.forBrightness(example.brightness),
        shadows: DesignShadows.forBrightness(example.brightness),
      );

      expect(surface.borderRadius, 14);
      expect(surface.look.fill, expectedLook.fill);
      expect(surface.look.border, expectedLook.border);
      expect(surface.look.shadows, expectedLook.shadows);
      expect(content.left, card.left + _border + _inlinePadding);
      expect(content.right, card.right - _border - _inlinePadding);
      expect(content.top, card.top + _border + _blockPadding);
      expect(card.bottom, content.bottom + _blockPadding + _border);

      if (example.hasMenu) {
        final menu = tester.getRect(find.byKey(_menuKey));

        expect(menu.top, card.top + _border + _menuInset);
        expect(menu.right, card.right - _border - _menuInset);
      }
    }
  });

  testWidgets('QuestionHeading property sets the .test-question text', (
    tester,
  ) async {
    final examples = examplesOf(
      (random) => (
        generatedQuestion(random),
        integerBetween(random, 300, 670).toDouble(),
      ),
      runs: 10,
    );

    for (final (question, width) in examples) {
      await tester.pumpWidget(
        hostedInTheme(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: QuestionHeading(question)),
          ),
          brightness: Brightness.light,
        ),
      );

      final style = renderedStyleOf(tester, question);
      final heading = tester.getRect(find.byType(QuestionHeading));
      final paragraph = tester.getRect(findShownText(question));

      expect(style.fontSize, 20);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.height, 1.4);
      expect(paragraph.left, heading.left);
      expect(paragraph.right, lessThanOrEqualTo(heading.right - _menuReserve));
    }
  });
}
