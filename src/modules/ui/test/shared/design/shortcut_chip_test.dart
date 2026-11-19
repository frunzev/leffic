import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_divider.dart';
import 'package:leffic/shared/design/shortcut_chip.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const double _accentFillOpacity = 0.14;

({Color fill, Color ink}) _accentChip(Color accent) {
  return (fill: accent.withValues(alpha: _accentFillOpacity), ink: accent);
}

({Color fill, Color ink}) _cssColoursOf(
  ShortcutChipTone tone,
  DesignColors colors,
) {
  return switch (tone) {
    ShortcutChipTone.plain => (
      fill: colors.surfaceTertiary,
      ink: colors.inkSecondary,
    ),
    ShortcutChipTone.onBrand => (fill: colors.onBrandChip, ink: colors.onBrand),
    ShortcutChipTone.again => _accentChip(colors.again),
    ShortcutChipTone.hard => _accentChip(colors.hard),
    ShortcutChipTone.good => _accentChip(colors.good),
  };
}

void main() {
  testWidgets('ShortcutChip property is a 22px chip in its tone colours', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final (label, tone) in examplesOf(
      (random) =>
          (wordOf(random, maximum: 6), oneOf(random, ShortcutChipTone.values)),
      runs: 10,
    )) {
      await tester.pumpWidget(
        hostedPlainly(
          Center(
            child: ShortcutChip(label: label, tone: tone),
          ),
        ),
      );

      final chip = tester.getRect(find.byType(ShortcutChip));
      final text = tester.getRect(find.text(label));
      final style = renderedStyleOf(tester, label);
      final decorated = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(ShortcutChip),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = decorated.decoration as BoxDecoration;
      final cssColours = _cssColoursOf(tone, colors);

      expect(chip.height, 22);
      expect(chip.width, greaterThanOrEqualTo(22));
      expect(text.left - chip.left, 8);
      expect(style.fontSize, 12);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.height, 1);
      expect(style.color, cssColours.ink);
      expect(decoration.color, cssColours.fill);
      expect(decoration.borderRadius, BorderRadius.circular(8));
    }
  });

  testWidgets('DesignDivider property is one line-coloured pixel', (
    tester,
  ) async {
    for (final width in examplesOf(
      (random) => integerBetween(random, 40, 600).toDouble(),
      runs: 6,
    )) {
      await tester.pumpWidget(
        hostedPlainly(
          Center(
            child: SizedBox(width: width, child: const DesignDivider()),
          ),
        ),
      );

      final line = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(DesignDivider),
          matching: find.byType(ColoredBox),
        ),
      );

      expect(tester.getSize(find.byType(DesignDivider)), Size(width, 1));
      expect(line.color, DesignColors.forBrightness(Brightness.light).line);
    }
  });
}
