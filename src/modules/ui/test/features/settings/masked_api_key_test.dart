import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/settings/masked_api_key.dart';

import '../../support/property.dart';

void main() {
  test('maskApiKey property shows only the ends of a long key', () {
    forAll((random) => tokenOf(random, minimum: 15, maximum: 80), (key) {
      final masked = maskApiKey(key);

      final shownStart = key.substring(0, 3);
      final shownEnd = key.substring(key.length - 4);

      expect(masked, '$shownStart…$shownEnd');
      expect(masked.contains(key.substring(3, key.length - 4)), isFalse);
    });
  });

  test('maskApiKey property hides a short key completely', () {
    forAll((random) => tokenOf(random, maximum: 14), (key) {
      expect(maskApiKey(key), '…');
    });
  });
}
