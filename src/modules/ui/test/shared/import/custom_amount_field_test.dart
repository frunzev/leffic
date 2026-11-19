import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/import/custom_amount_field.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

const double _sectionWidth = 550;

Widget _sized(Widget child) {
  return hostedPlainly(
    Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: _sectionWidth, child: child),
    ),
  );
}

void main() {
  testWidgets('CustomAmountField property follows the amount it is given', (
    tester,
  ) async {
    for (final amounts in examplesOf(
      (random) => [
        for (var index = 0; index < 3; index++)
          oneOf(random, [null, integerBetween(random, 1, 99)]),
      ],
      runs: 5,
    )) {
      for (final amount in amounts) {
        await tester.pumpWidget(
          _sized(
            Align(
              alignment: Alignment.centerLeft,
              child: CustomAmountField(amount: amount, onChanged: (value) {}),
            ),
          ),
        );

        final field = tester.widget<TextField>(find.byType(TextField));

        expect(field.controller?.text, amount?.toString() ?? '');
        expect(tester.getSize(find.byType(CustomAmountField)).width, 72);
      }
    }
  });

  testWidgets('CustomAmountField property reports only whole amounts', (
    tester,
  ) async {
    for (final typed in examplesOf(
      (random) => oneOf(random, [
        '${integerBetween(random, 1, 99)}',
        '0',
        wordOf(random),
        ' ',
      ]),
      runs: 8,
    )) {
      final reported = <int?>[];

      await tester.pumpWidget(
        _sized(
          CustomAmountField(
            key: UniqueKey(),
            amount: null,
            onChanged: reported.add,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), typed);

      final parsed = int.tryParse(typed);
      final expected = parsed != null && parsed >= 1 ? parsed : null;

      expect(reported, [expected]);
    }
  });
}
