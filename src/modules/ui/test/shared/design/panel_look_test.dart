import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_shadows.dart';
import 'package:leffic/shared/design/panel_look.dart';

import '../../support/property.dart';

void main() {
  test('raisedPanelLookOf property is the surface, line and raised panel', () {
    forAll((random) => oneOf(random, Brightness.values), (brightness) {
      final colors = DesignColors.forBrightness(brightness);
      final shadows = DesignShadows.forBrightness(brightness);

      final look = raisedPanelLookOf(colors: colors, shadows: shadows);

      expect(look.fill, colors.surface);
      expect(look.border, BorderSide(color: colors.line));
      expect(look.shadows, shadows.raised);
      expect(look.edgeHighlight, shadows.edgeHighlight);
    }, runs: 10);
  });

  test(
    'floatingPanelLookOf property is the surface, line and level-3 panel',
    () {
      forAll((random) => oneOf(random, Brightness.values), (brightness) {
        final colors = DesignColors.forBrightness(brightness);
        final shadows = DesignShadows.forBrightness(brightness);

        final look = floatingPanelLookOf(colors: colors, shadows: shadows);

        expect(look.fill, colors.surface);
        expect(look.border, BorderSide(color: colors.line));
        expect(look.shadows, shadows.level3);
        expect(look.edgeHighlight, shadows.edgeHighlight);
      }, runs: 10);
    },
  );
}
