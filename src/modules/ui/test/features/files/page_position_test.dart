import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/files/page_position.dart';
import 'package:leffic/shared/design/design_colors.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

(int, int, Brightness) _position(Random random) {
  final pageCount = integerBetween(random, 1, 400);
  final page = integerBetween(random, 1, pageCount);

  return (page, pageCount, oneOf(random, Brightness.values));
}

void main() {
  testWidgets('PagePosition property writes the position like the CSS', (
    tester,
  ) async {
    for (final (page, pageCount, brightness) in examplesOf(
      _position,
      runs: 8,
    )) {
      final colors = DesignColors.forBrightness(brightness);

      await tester.pumpWidget(
        hostedInTheme(
          Center(
            child: PagePosition(page: page, pageCount: pageCount),
          ),
          brightness: brightness,
        ),
      );

      final position = renderedStyleOf(tester, 'Page $page of $pageCount');

      expect(position.fontSize, 14);
      expect(position.color, colors.inkSecondary);
      expect(position.fontFeatures, [const FontFeature.tabularFigures()]);
      expect(find.byType(GestureDetector), findsNothing);
    }
  });
}
