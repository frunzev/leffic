import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/icons/design_icon.dart';
import 'package:leffic/shared/design/spinner.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

double _turnsOf(WidgetTester tester) {
  final rotation = tester.widget<RotationTransition>(
    find.descendant(
      of: find.byType(Spinner),
      matching: find.byType(RotationTransition),
    ),
  );

  return rotation.turns.value;
}

Widget _spinnerWithMotion({required bool disableAnimations}) {
  return hostedPlainly(
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: const Center(child: Spinner()),
    ),
  );
}

void main() {
  testWidgets('Spinner property is a 32px brand head on a line track', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    await tester.pumpWidget(_spinnerWithMotion(disableAnimations: false));

    final painters = tester
        .widgetList<ShapeView>(find.byType(ShapeView))
        .map((view) => view.color)
        .toList();

    expect(tester.getSize(find.byType(Spinner)), const Size.square(32));
    expect(painters, [colors.line, colors.brand]);
  });

  testWidgets('Spinner property turns once every 0.9s, 2.4s when reduced', (
    tester,
  ) async {
    for (final (disableAnimations, elapsedMilliseconds) in examplesOf(
      (random) => (random.nextBool(), integerBetween(random, 1, 899)),
      runs: 8,
    )) {
      final period = disableAnimations ? 2400 : 900;

      await tester.pumpWidget(
        _spinnerWithMotion(disableAnimations: disableAnimations),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        _spinnerWithMotion(disableAnimations: disableAnimations),
      );
      await tester.pump(Duration(milliseconds: elapsedMilliseconds));

      expect(_turnsOf(tester), closeTo(elapsedMilliseconds / period, 1e-3));
    }
  });
}
