import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/import/amount_choice.dart';

import '../../support/property.dart';
import 'import_fakes.dart';

void main() {
  test('AmountMode property offers Auto, 10, 20 and Custom in order', () {
    forAll((random) => random.nextInt(AmountMode.values.length), (index) {
      const labels = ['Auto', '10', '20', 'Custom'];
      const presets = [null, 10, 20, null];
      final mode = AmountMode.values[index];

      expect(mode.label, labels[index]);
      expect(mode.presetAmount, presets[index]);
    });
  });

  test('AmountChoice.amount property follows the chosen mode', () {
    forAll(generatedAmountChoice, (amountChoice) {
      final expected = amountChoice.mode == AmountMode.custom
          ? amountChoice.customAmount
          : amountChoice.mode.presetAmount;

      expect(amountChoice.amount, expected);
    });
  });

  test('AmountChoice.automatic property asks for no amount', () {
    forAll((random) => oneOf(random, AmountMode.values), (mode) {
      final automatic = AmountChoice.automatic;

      expect(automatic.mode, AmountMode.automatic);
      expect(automatic.amount, isNull);
      expect(automatic.withMode(mode).amount, mode.presetAmount);
    });
  });

  test('AmountChoice.withMode property changes only the mode', () {
    forAll(
      (random) =>
          (generatedAmountChoice(random), oneOf(random, AmountMode.values)),
      (example) {
        final (amountChoice, mode) = example;
        final changed = amountChoice.withMode(mode);

        expect(changed.mode, mode);
        expect(changed.customAmount, amountChoice.customAmount);
      },
    );
  });

  test('AmountChoice.withCustomAmount property asks for that amount', () {
    forAll(
      (random) => (
        generatedAmountChoice(random),
        oneOf(random, [null, integerBetween(random, 1, 99)]),
      ),
      (example) {
        final (amountChoice, customAmount) = example;
        final changed = amountChoice.withCustomAmount(customAmount);

        expect(changed.mode, AmountMode.custom);
        expect(changed.amount, customAmount);
      },
    );
  });
}
