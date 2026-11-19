import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/meter.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const Key _fillKey = ValueKey('meter fill');

void main() {
  testWidgets('Meter property fills its share of the track', (tester) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final (width, fraction) in examplesOf(
      (random) => (
        integerBetween(random, 40, 780).toDouble(),
        integerBetween(random, 0, 100) / 100,
      ),
      runs: 16,
    )) {
      await tester.pumpWidget(
        hostedPlainly(
          Center(
            child: SizedBox(
              width: width,
              child: Meter(fraction: fraction),
            ),
          ),
        ),
      );

      final track = tester.getRect(find.byType(Meter));
      final fill = tester.getRect(find.byKey(_fillKey));
      final fillBox = tester.widget<DecoratedBox>(find.byKey(_fillKey));
      final trackBox = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(Meter),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );

      expect(track.size, Size(width, 6));
      expect(fill.left, track.left);
      expect(fill.width, closeTo(width * fraction, 1e-6));
      expect(fill.height, 6);
      expect((fillBox.decoration as BoxDecoration).color, colors.brand);
      expect(
        (trackBox.decoration as BoxDecoration).color,
        colors.surfaceTertiary,
      );
    }
  });

  testWidgets('Meter property refuses a share outside zero to one', (
    tester,
  ) async {
    for (final fraction in examplesOf(
      (random) => oneOf(random, [
        -integerBetween(random, 1, 100) / 100,
        1 + integerBetween(random, 1, 100) / 100,
      ]),
      runs: 4,
    )) {
      await tester.pumpWidget(hostedPlainly(Meter(fraction: fraction)));

      expect(tester.takeException(), isArgumentError);
    }
  });

  testWidgets('MeterBlock property puts the legend 8px above the meter', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final (start, end, fraction) in examplesOf(
      (random) => (
        'Reviewed ${wordOf(random)}',
        '${integerBetween(random, 0, 99)} left',
        integerBetween(random, 0, 100) / 100,
      ),
      runs: 8,
    )) {
      await tester.pumpWidget(
        hostedPlainly(
          Center(
            child: SizedBox(
              width: 600,
              child: MeterBlock(
                startLabel: start,
                endLabel: end,
                fraction: fraction,
              ),
            ),
          ),
        ),
      );

      final block = tester.getRect(find.byType(MeterBlock));
      final startBox = tester.getRect(find.text(start));
      final endBox = tester.getRect(find.text(end));
      final meter = tester.getRect(find.byType(Meter));
      final style = renderedStyleOf(tester, start);

      expect(startBox.left, block.left);
      expect(endBox.right, block.right);
      expect(meter.top - startBox.bottom, 8);
      expect(style.fontSize, 14);
      expect(style.color, colors.inkTertiary);
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    }
  });
}
