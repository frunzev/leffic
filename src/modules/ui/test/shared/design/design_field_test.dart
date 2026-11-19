import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_field.dart';
import 'package:leffic/shared/design/icons/design_icon.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const Key _inputKey = Key('field input');

typedef _FieldExample = ({String label, String? hint, String? error});

void main() {
  testWidgets('DesignField property stacks label, input, hint and error', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final example in examplesOf<_FieldExample>(
      (random) => (
        label: 'Label ${wordOf(random)}',
        hint: oneOf(random, [null, 'Hint ${wordOf(random)}']),
        error: oneOf(random, [null, 'Error ${wordOf(random)}']),
      ),
      runs: 12,
    )) {
      final hint = example.hint;
      final error = example.error;

      await tester.pumpWidget(
        hostedPlainly(
          Center(
            child: SizedBox(
              width: 360,
              child: DesignField(
                label: example.label,
                hint: hint,
                error: error,
                input: const SizedBox(key: _inputKey, height: 40),
              ),
            ),
          ),
        ),
      );

      final label = tester.getRect(find.text(example.label));
      final input = tester.getRect(find.byKey(_inputKey));
      final labelStyle = renderedStyleOf(tester, example.label);

      expect(input.top - label.bottom, 8);
      expect(labelStyle.fontSize, 14);
      expect(labelStyle.fontWeight, FontWeight.w500);
      expect(labelStyle.color, colors.ink);
      var previousBottom = input.bottom;

      if (hint != null) {
        final hintBox = tester.getRect(find.text(hint));
        final hintStyle = renderedStyleOf(tester, hint);

        expect(hintBox.top - previousBottom, 8);
        expect(hintStyle.fontSize, 12);
        expect(hintStyle.color, colors.inkTertiary);
        previousBottom = hintBox.bottom;
      }

      if (error != null) {
        final errorRow = tester.getRect(
          find.ancestor(of: find.text(error), matching: find.byType(Row)),
        );
        final errorIcon = tester.getRect(find.byType(DesignIcon));
        final errorText = tester.getRect(find.text(error));
        final errorStyle = renderedStyleOf(tester, error);
        final iconWidget = tester.widget<DesignIcon>(find.byType(DesignIcon));

        expect(errorRow.top - previousBottom, 8);
        expect(iconWidget.icon, DesignIcons.failure);
        expect(errorIcon.size, const Size.square(16));
        expect(errorIcon.top - errorRow.top, 4);
        expect(errorText.left - errorIcon.right, 4);
        expect(errorStyle.fontSize, 14);
        expect(errorStyle.color, colors.danger);
      }
    }
  });

  testWidgets('FieldError property is the .field-error danger row', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final message in examplesOf(
      (random) => 'Error ${wordOf(random)}',
      runs: 5,
    )) {
      await tester.pumpWidget(
        hostedPlainly(
          Center(
            child: SizedBox(width: 360, child: FieldError(message: message)),
          ),
        ),
      );

      final row = tester.getRect(find.byType(FieldError));
      final icon = tester.getRect(find.byType(DesignIcon));
      final text = tester.getRect(find.text(message));
      final style = renderedStyleOf(tester, message);

      expect(icon.size, const Size.square(16));
      expect(icon.top - row.top, 4);
      expect(text.left - icon.right, 4);
      expect(style.fontSize, 14);
      expect(style.color, colors.danger);
    }
  });
}
