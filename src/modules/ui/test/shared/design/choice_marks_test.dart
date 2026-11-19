import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/choice_marks.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_shadows.dart';
import 'package:leffic/shared/design/pressable.dart';
import 'package:leffic/shared/design/surface_box.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

InteractionState _stateOf(Random random) {
  return InteractionState(
    isEnabled: true,
    isHovered: random.nextBool(),
    isPressed: random.nextBool(),
    isFocused: random.nextBool(),
  );
}

void main() {
  test('choiceMarkLookOf property matches the app-forms.css marks', () {
    forAll(
      (random) => (
        _stateOf(random),
        random.nextBool(),
        oneOf(random, Brightness.values),
      ),
      (example) {
        final (state, isChecked, brightness) = example;
        final colors = DesignColors.forBrightness(brightness);
        final shadows = DesignShadows.forBrightness(brightness);
        final look = choiceMarkLookOf(
          state: state,
          isChecked: isChecked,
          colors: colors,
          shadows: shadows,
        );
        final expectedBorder = isChecked
            ? const Color(0x00000000)
            : state.isHovered
            ? colors.brand
            : colors.lineHover;

        expect(look.fill, isChecked ? colors.brand : colors.surface);
        expect(look.border, BorderSide(color: expectedBorder));
        expect(look.shadows, shadows.raised);
        expect(look.edgeHighlight, shadows.edgeHighlight);
      },
    );
  });

  testWidgets('DesignCheckbox property is an 18px box that toggles', (
    tester,
  ) async {
    for (final isChecked in examplesOf((random) => random.nextBool())) {
      final changes = <bool>[];

      await tester.pumpWidget(
        hostedPlainly(
          Center(
            child: DesignCheckbox(isChecked: isChecked, onChanged: changes.add),
          ),
        ),
      );

      final surface = tester.widget<SurfaceBox>(find.byType(SurfaceBox));

      expect(tester.getSize(find.byType(DesignCheckbox)), const Size(18, 18));
      expect(surface.borderRadius, 6);
      expect(find.byType(CheckMark), isChecked ? findsOneWidget : findsNothing);

      await tester.tap(find.byType(DesignCheckbox));

      expect(changes, [!isChecked]);
    }
  });

  testWidgets('DesignRadio property is an 18px circle that selects', (
    tester,
  ) async {
    for (final (value, groupValue) in examplesOf(
      (random) => (integerBetween(random, 0, 2), integerBetween(random, 0, 2)),
    )) {
      final selections = <int>[];

      await tester.pumpWidget(
        hostedPlainly(
          Center(
            child: DesignRadio<int>(
              value: value,
              groupValue: groupValue,
              onChanged: selections.add,
            ),
          ),
        ),
      );

      final surface = tester.widget<SurfaceBox>(find.byType(SurfaceBox));
      final isSelected = value == groupValue;

      expect(tester.getSize(find.byType(DesignRadio<int>)), const Size(18, 18));
      expect(surface.borderRadius, 999);
      expect(find.byType(RadioDot), isSelected ? findsOneWidget : findsNothing);

      await tester.tap(find.byType(DesignRadio<int>));

      expect(selections, [if (!isSelected) value]);
    }
  });

  testWidgets('RadioDot property is a 7px brand-mark dot', (tester) async {
    await tester.pumpWidget(hostedPlainly(const Center(child: RadioDot())));

    final dot = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(RadioDot),
        matching: find.byType(DecoratedBox),
      ),
    );

    expect(tester.getSize(find.byType(RadioDot)), const Size.square(7));
    expect(
      (dot.decoration as BoxDecoration).color,
      DesignColors.forBrightness(Brightness.light).brandMark,
    );
  });
}
