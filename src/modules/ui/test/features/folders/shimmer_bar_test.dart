import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/folders/shimmer_bar.dart';
import 'package:leffic/shared/design/design_colors.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

void main() {
  test('shimmerGradient property shows a quarter sliding to the start', () {
    final colors = DesignColors.forBrightness(Brightness.light);

    forAll((random) => random.nextDouble(), (position) {
      final gradient = shimmerGradient(
        position: position,
        base: colors.surfaceTertiary,
        highlight: colors.hover,
      );
      final begin = gradient.begin as Alignment;
      final end = gradient.end as Alignment;
      final span = end.x - begin.x;
      final barStart = (-1 - begin.x) / span;
      final barEnd = (1 - begin.x) / span;

      expect(gradient.colors, [
        colors.surfaceTertiary,
        colors.hover,
        colors.surfaceTertiary,
      ]);
      expect(gradient.stops, [0.25, 0.37, 0.63]);
      expect(barEnd - barStart, closeTo(0.25, 1e-9));
      expect(barStart, closeTo(0.75 * position, 1e-9));
    });
  });

  testWidgets('ShimmerBar property sweeps unless motion is reduced', (
    tester,
  ) async {
    for (final isReduced in [false, true]) {
      await tester.pumpWidget(
        hostedInLightTheme(
          MediaQuery(
            data: MediaQueryData(disableAnimations: isReduced),
            child: const Center(child: ShimmerBar(width: 80)),
          ),
        ),
      );
      await tester.pump();

      expect(tester.hasRunningAnimations, !isReduced);
      expect(tester.getSize(find.byType(ShimmerBar)), const Size(80, 12));
    }
  });
}
