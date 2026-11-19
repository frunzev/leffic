import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_metrics.dart';

import '../../support/property.dart';

const double _tolerance = 1e-9;

void main() {
  test('Spacing property follows the CSS space scale in order', () {
    const scale = [
      Spacing.step1,
      Spacing.step2,
      Spacing.step3,
      Spacing.step4,
      Spacing.step5,
      Spacing.step6,
      Spacing.step7,
      Spacing.step8,
    ];

    expect(scale, [4, 8, 12, 16, 24, 32, 48, 64]);
  });

  test('TextSizes property follows the CSS text scale in order', () {
    const scale = [
      TextSizes.extraSmall,
      TextSizes.small,
      TextSizes.medium,
      TextSizes.large,
      TextSizes.extraLarge,
      TextSizes.doubleExtraLarge,
      TextSizes.tripleExtraLarge,
    ];

    expect(scale, [12, 14, 16, 20, 24, 32, 48]);
  });

  test('Radii property follows the CSS radius scale', () {
    expect(
      [Radii.extraSmall, Radii.small, Radii.medium, Radii.large, Radii.pill],
      [6, 8, 10, 14, 999],
    );
  });

  test('ControlHeights property follows the CSS control heights', () {
    expect(
      [
        ControlHeights.small,
        ControlHeights.regular,
        ControlHeights.large,
        ControlHeights.extraLarge,
      ],
      [34, 40, 44, 56],
    );
  });

  test('LayoutSizes property keeps the CSS layout sizes', () {
    expect(LayoutSizes.meterHeight, 6);
    expect(LayoutSizes.railWidth, 72);
    expect(LayoutSizes.railBarHeight, 60);
    expect(IconSizes.regular, 20);
    expect(IconSizes.small, 18);
    expect(baseLineHeight, 1.55);
  });

  test('widthOfCharacters property adds up across character counts', () {
    forAll(
      (random) => (
        integerBetween(random, 0, 200),
        integerBetween(random, 0, 200),
        integerBetween(random, 8, 64).toDouble(),
      ),
      (example) {
        final (firstCount, secondCount, textSize) = example;
        final together = widthOfCharacters(
          firstCount + secondCount,
          textSize: textSize,
        );
        final apart =
            widthOfCharacters(firstCount, textSize: textSize) +
            widthOfCharacters(secondCount, textSize: textSize);

        expect(together, closeTo(apart, _tolerance));
        expect(together, greaterThanOrEqualTo(0));
      },
    );
  });

  test('widthOfCharacters property grows in proportion to the font size', () {
    forAll(
      (random) => (
        integerBetween(random, 1, 200),
        integerBetween(random, 8, 64).toDouble(),
      ),
      (example) {
        final (count, textSize) = example;
        final doubled = widthOfCharacters(count, textSize: textSize * 2);
        final single = widthOfCharacters(count, textSize: textSize);

        expect(doubled, closeTo(single * 2, _tolerance));
      },
    );
  });

  test('Motion property is the CSS ease of 140ms', () {
    final curve = Motion.curve;

    expect(Motion.duration, const Duration(milliseconds: 140));
    expect([curve.a, curve.b, curve.c, curve.d], [0.2, 0, 0, 1]);
  });
}
