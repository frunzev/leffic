import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/folders/unit_badge.dart';
import 'package:leffic/shared/design/design_colors.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

void main() {
  testWidgets('UnitBadge property is styled like .unit-badge', (tester) async {
    for (final example in examplesOf(
      (random) => (
        label: '${integerBetween(random, 1, 999)} due',
        brightness: oneOf(random, Brightness.values),
      ),
      runs: 8,
    )) {
      final colors = DesignColors.forBrightness(example.brightness);

      await tester.pumpWidget(
        hostedInTheme(
          Center(child: UnitBadge(label: example.label)),
          brightness: example.brightness,
        ),
      );

      final badge = tester.getRect(find.byType(UnitBadge));
      final text = tester.getRect(find.text(example.label));
      final style = renderedStyleOf(tester, example.label);
      final fill = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(UnitBadge),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = fill.decoration as BoxDecoration;

      expect(text.left - badge.left, 8);
      expect(badge.right - text.right, 8);
      expect(text.top - badge.top, 2);
      expect(badge.bottom - text.bottom, 2);
      expect(text.height, closeTo(12 * 1.55, 0.5));
      expect(style.fontSize, 12);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.color, colors.brandStrong);
      expect(decoration.color, colors.brandSurfaceStrong);
      expect(decoration.borderRadius, BorderRadius.circular(999));
      expect(tester.widget<Text>(find.text(example.label)).maxLines, 1);
    }
  });
}
