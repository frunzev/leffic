import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/assessment/answer_option_button.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/pressable.dart';
import 'package:leffic/shared/design/surface_box.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const Color _transparent = Color(0x00000000);
const double _minimumHeight = 52;
const double _keySide = 24;
const double _rowInset = 17;
const double _blockInset = 9;
const double _keyGap = 12;

typedef _OptionExample = ({
  Brightness brightness,
  double width,
  String letter,
  String text,
  bool isChosen,
});

_OptionExample _optionExampleOf(Random random) {
  return (
    brightness: oneOf(random, Brightness.values),
    width: integerBetween(random, 400, 670).toDouble(),
    letter: oneOf(random, ['A', 'B', 'C', 'D', 'E']),
    text: 'Answer ${wordOf(random, maximum: 8)}',
    isChosen: random.nextBool(),
  );
}

InteractionState _stateOf(Random random) {
  return InteractionState(
    isEnabled: true,
    isHovered: random.nextBool(),
    isPressed: random.nextBool(),
    isFocused: random.nextBool(),
  );
}

Widget _optionOf(_OptionExample example, {VoidCallback? onPressed}) {
  return hostedInTheme(
    Center(
      child: SizedBox(
        width: example.width,
        child: AnswerOptionButton(
          letter: example.letter,
          text: example.text,
          isChosen: example.isChosen,
          onPressed: onPressed ?? () {},
        ),
      ),
    ),
    brightness: example.brightness,
  );
}

SurfaceLook _lookOf(WidgetTester tester) {
  return tester.widget<SurfaceBox>(find.byType(SurfaceBox)).look;
}

void main() {
  test('answerOptionLookOf property follows the .test-option states', () {
    forAll(
      (random) => (
        oneOf(random, Brightness.values),
        _stateOf(random),
        random.nextBool(),
      ),
      (example) {
        final (brightness, state, isChosen) = example;
        final colors = DesignColors.forBrightness(brightness);
        final look = answerOptionLookOf(
          state: state,
          isChosen: isChosen,
          colors: colors,
        );
        final (border, fill, keyFill, keyInk) = switch ((
          isChosen,
          state.isHovered,
        )) {
          (true, _) => (
            colors.brand,
            colors.brandSurface,
            colors.brand,
            colors.onBrand,
          ),
          (false, true) => (
            colors.lineHover,
            colors.surfaceTertiary,
            colors.surface,
            colors.inkSecondary,
          ),
          (false, false) => (
            colors.line,
            colors.surfaceSecondary,
            colors.surfaceTertiary,
            colors.inkSecondary,
          ),
        };

        expect(look.surface.border, BorderSide(color: border));
        expect(look.surface.fill, fill);
        expect(look.surface.shadows, isEmpty);
        expect(look.surface.edgeHighlight, _transparent);
        expect(look.keyFill, keyFill);
        expect(look.keyInk, keyInk);
      },
    );
  });

  testWidgets('AnswerOptionButton property lays out the .test-option row', (
    tester,
  ) async {
    for (final example in examplesOf(_optionExampleOf, runs: 10)) {
      await tester.pumpWidget(_optionOf(example));

      final colors = DesignColors.forBrightness(example.brightness);
      final option = tester.getRect(find.byType(AnswerOptionButton));
      final key = tester.getRect(find.byType(OptionLetterBadge));
      final text = tester.getRect(find.text(example.text));
      final badge = tester.widget<OptionLetterBadge>(
        find.byType(OptionLetterBadge),
      );
      final restingLook = answerOptionLookOf(
        state: const InteractionState(
          isEnabled: true,
          isHovered: false,
          isPressed: false,
          isFocused: false,
        ),
        isChosen: example.isChosen,
        colors: colors,
      );

      expect(option.height, _minimumHeight);
      expect(key.size, const Size(_keySide, _keySide));
      expect(key.left, option.left + _rowInset);
      expect(key.center.dy, option.center.dy);
      expect(text.left, key.right + _keyGap);
      expect(renderedStyleOf(tester, example.text).fontSize, 16);
      expect(renderedStyleOf(tester, example.text).color, colors.ink);
      expect(renderedStyleOf(tester, example.letter).fontSize, 12);
      expect(
        renderedStyleOf(tester, example.letter).fontWeight,
        FontWeight.w600,
      );
      expect(badge.fill, restingLook.keyFill);
      expect(badge.ink, restingLook.keyInk);
      expect(_lookOf(tester).fill, restingLook.surface.fill);
      expect(_lookOf(tester).border, restingLook.surface.border);
      expect(
        tester.widget<SurfaceBox>(find.byType(SurfaceBox)).borderRadius,
        10,
      );
    }
  });

  testWidgets('AnswerOptionButton property grows around a long answer', (
    tester,
  ) async {
    final examples = examplesOf((random) {
      final example = _optionExampleOf(random);
      final words = [for (var index = 0; index < 40; index++) wordOf(random)];

      return (
        brightness: example.brightness,
        width: example.width,
        letter: example.letter,
        text: words.join(' '),
        isChosen: example.isChosen,
      );
    }, runs: 6);

    for (final example in examples) {
      await tester.pumpWidget(_optionOf(example));

      final option = tester.getRect(find.byType(AnswerOptionButton));
      final text = tester.getRect(find.text(example.text));

      expect(option.height, max(_minimumHeight, text.height + 2 * _blockInset));
      expect(text.top, option.top + _blockInset);
    }
  });

  testWidgets('AnswerOptionButton property lights up on hover and taps', (
    tester,
  ) async {
    for (final example in examplesOf(_optionExampleOf, runs: 6)) {
      var tapCount = 0;

      await tester.pumpWidget(_optionOf(example, onPressed: () => tapCount++));

      final colors = DesignColors.forBrightness(example.brightness);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);

      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(AnswerOptionButton)));
      await tester.pumpAndSettle();

      final hoveredFill = example.isChosen
          ? colors.brandSurface
          : colors.surfaceTertiary;

      expect(_lookOf(tester).fill, hoveredFill);

      await tester.tap(find.byType(AnswerOptionButton));

      expect(tapCount, 1);

      await mouse.removePointer();
    }
  });
}
