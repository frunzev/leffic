import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/theme/leffic_theme.dart';

import '../../support/property.dart';

void main() {
  test('lefficTheme property sets the app-base.css text on surface-2', () {
    forAll((random) => oneOf(random, Brightness.values), (brightness) {
      final theme = lefficTheme(brightness);
      final colors = DesignColors.forBrightness(brightness);
      final baseText = theme.textTheme.bodyMedium;

      expect(theme.brightness, brightness);
      expect(theme.scaffoldBackgroundColor, colors.surfaceSecondary);
      expect(theme.canvasColor, colors.surfaceSecondary);
      expect(baseText?.fontSize, 16);
      expect(baseText?.height, 1.55);
      expect(baseText?.fontWeight, FontWeight.w400);
      expect(baseText?.letterSpacing, -0.31);
      expect(baseText?.fontVariations, const [FontVariation('opsz', 16)]);
      expect(baseText?.color, colors.ink);
      expect(baseText?.leadingDistribution, TextLeadingDistribution.even);
    });
  });

  test('lefficTheme property keeps standard density on every platform', () {
    forAll((random) => oneOf(random, Brightness.values), (brightness) {
      expect(lefficTheme(brightness).visualDensity, VisualDensity.standard);
    });
  });

  test('lefficTheme property maps the brand tokens onto the scheme', () {
    forAll((random) => oneOf(random, Brightness.values), (brightness) {
      final scheme = lefficTheme(brightness).colorScheme;
      final colors = DesignColors.forBrightness(brightness);

      expect(scheme.brightness, brightness);
      expect(scheme.primary, colors.brand);
      expect(scheme.onPrimary, colors.onBrand);
      expect(scheme.error, colors.danger);
      expect(scheme.surface, colors.surface);
      expect(scheme.onSurface, colors.ink);
      expect(scheme.onSurfaceVariant, colors.inkSecondary);
      expect(scheme.outline, colors.lineStrong);
      expect(scheme.outlineVariant, colors.line);
    });
  });

  testWidgets('lefficTheme property gives Material text the base style', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          theme: lefficTheme(brightness),
          home: const Material(child: Text('base')),
        ),
      );

      final style = DefaultTextStyle.of(tester.element(find.text('base')))
          .style;

      expect(style.fontSize, 16);
      expect(style.letterSpacing, -0.31);
      expect(style.fontVariations, const [FontVariation('opsz', 16)]);
      expect(style.height, 1.55);
      expect(style.color, DesignColors.forBrightness(brightness).ink);
    }
  });
}
