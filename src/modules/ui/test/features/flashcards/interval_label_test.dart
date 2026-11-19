import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/flashcards/interval_label.dart';

import '../../support/property.dart';

const Map<String, int> _secondsPerUnit = {
  's': 1,
  'min': 60,
  'h': 3600,
  'days': 86400,
  'mo': 2592000,
  'y': 31536000,
};
const List<String> _unitsSmallestFirst = ['s', 'min', 'h', 'days', 'mo', 'y'];

void main() {
  test('intervalLabel property counts whole units of the largest fit', () {
    forAll(
      (random) {
        final unit = oneOf(random, _unitsSmallestFirst);
        final unitSeconds = _secondsPerUnit[unit]!;

        return integerBetween(random, unitSeconds, unitSeconds * 20);
      },
      (seconds) {
        final [count, unit] = intervalLabel(seconds).split(' ');
        final unitSeconds = _secondsPerUnit[unit]!;
        final whole = int.parse(count);
        final position = _unitsSmallestFirst.indexOf(unit);

        expect(whole * unitSeconds, lessThanOrEqualTo(seconds));
        expect((whole + 1) * unitSeconds, greaterThan(seconds));

        if (position + 1 < _unitsSmallestFirst.length) {
          final largerUnit = _unitsSmallestFirst[position + 1];

          expect(seconds, lessThan(_secondsPerUnit[largerUnit]!));
        }
      },
    );
  });

  test('intervalLabel property shows seconds below one minute', () {
    forAll((random) => integerBetween(random, 0, 59), (seconds) {
      expect(intervalLabel(seconds), '$seconds s');
    });
  });
}
