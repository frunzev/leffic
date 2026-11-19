import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/card_look.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_shadows.dart';

import '../../support/property.dart';

void main() {
  test('cardLookOf property is the surface, line and shadow-2 card', () {
    forAll((random) => oneOf(random, Brightness.values), (brightness) {
      final colors = DesignColors.forBrightness(brightness);
      final shadows = DesignShadows.forBrightness(brightness);

      final look = cardLookOf(colors: colors, shadows: shadows);

      expect(look.fill, colors.surface);
      expect(look.border, BorderSide(color: colors.line));
      expect(look.shadows, shadows.level2);
      expect(look.edgeHighlight, shadows.edgeHighlight);
    }, runs: 10);
  });
}
