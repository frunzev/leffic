import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/focus_outline.dart';
import 'package:leffic/shared/design/pressable.dart';

import '../../support/property.dart';

InteractionState _stateFocused(bool isFocused) {
  return InteractionState(
    isEnabled: true,
    isHovered: false,
    isPressed: false,
    isFocused: isFocused,
  );
}

void main() {
  test('focusOutlineShape property centres a 2px stroke 2px outside', () {
    forAll(
      (random) => (
        Size(
          integerBetween(random, 1, 400).toDouble(),
          integerBetween(random, 1, 200).toDouble(),
        ),
        integerBetween(random, 0, 999).toDouble(),
      ),
      (example) {
        final (size, radius) = example;
        final outline = focusOutlineShape(size, radius);

        expect(outline.left, -3);
        expect(outline.top, -3);
        expect(outline.width, size.width + 6);
        expect(outline.height, size.height + 6);
        expect(outline.tlRadiusX, radius + 3);
        expect(outline.brRadiusY, radius + 3);
        expect(focusOutlineWidth, 2);
      },
    );
  });

  testWidgets('FocusOutline property draws the brand ring only on focus', (
    tester,
  ) async {
    for (final isFocused in examplesOf(
      (random) => random.nextBool(),
      runs: 6,
    )) {
      await tester.pumpWidget(
        Center(
          child: FocusOutline(
            state: _stateFocused(isFocused),
            borderRadius: 10,
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      );

      final painted = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(FocusOutline),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = painted.foregroundPainter as FocusOutlinePainter;
      final brand = DesignColors.forBrightness(Brightness.light).brand;

      expect(painter.color, isFocused ? brand : const Color(0x00000000));
      expect(painter.borderRadius, 10);
    }
  });
}
