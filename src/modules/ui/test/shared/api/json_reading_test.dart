import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/api/json_reading.dart';

import '../../support/property.dart';

void main() {
  test('readText property returns the stored text', () {
    forAll((random) => (wordOf(random), anyTextOf(random)), (example) {
      final (key, text) = example;

      expect(readText(<String, Object?>{key: text}, key), text);
    });
  });

  test('readText property refuses a missing or non-text field', () {
    forAll((random) => (wordOf(random), random.nextInt(1000)), (example) {
      final (key, number) = example;

      expect(
        () => readText(<String, Object?>{key: number}, key),
        throwsFormatException,
      );
      expect(() => readText(<String, Object?>{}, key), throwsFormatException);
    });
  });

  test('readTextOr property falls back only when the field is absent', () {
    forAll((random) => (wordOf(random), anyTextOf(random)), (example) {
      final (key, fallback) = example;

      expect(readTextOr(<String, Object?>{}, key, fallback), fallback);
      expect(readTextOr(<String, Object?>{key: null}, key, fallback), fallback);
      expect(readTextOr(<String, Object?>{key: 'kept'}, key, fallback), 'kept');
    });
  });

  test('readWholeNumber property accepts whole numbers only', () {
    forAll((random) => (wordOf(random), random.nextInt(100000)), (example) {
      final (key, number) = example;

      expect(readWholeNumber(<String, Object?>{key: number}, key), number);
      expect(
        () => readWholeNumber(<String, Object?>{key: '$number'}, key),
        throwsFormatException,
      );
    });
  });

  test('readWholeNumberOr property falls back for an absent field', () {
    forAll((random) => (wordOf(random), random.nextInt(1000)), (example) {
      final (key, fallback) = example;

      expect(readWholeNumberOr(<String, Object?>{}, key, fallback), fallback);
      expect(readWholeNumberOr(<String, Object?>{key: 7}, key, fallback), 7);
    });
  });

  test('readObject property returns nested objects and refuses others', () {
    forAll(wordOf, (key) {
      final nested = <String, Object?>{'inner': key};

      expect(readObject(<String, Object?>{key: nested}, key), nested);
      expect(
        () => readObject(<String, Object?>{key: <Object?>[]}, key),
        throwsFormatException,
      );
    });
  });

  test('readObjects property keeps every object of a list in order', () {
    forAll((random) => integerBetween(random, 0, 6), (count) {
      final entries = <Object?>[
        for (var index = 0; index < count; index++)
          <String, Object?>{'index': index},
      ];
      final objects = readObjects(<String, Object?>{'list': entries}, 'list');

      expect(
        objects.map((entry) => entry['index']),
        List.generate(count, (i) => i),
      );
    });
  });

  test('readTexts property keeps every text of a list in order', () {
    forAll((random) => [for (var i = 0; i < 4; i++) wordOf(random)], (texts) {
      expect(readTexts(<String, Object?>{'list': texts}, 'list'), texts);
      expect(
        () => readTexts(<String, Object?>{
          'list': <Object?>[1],
        }, 'list'),
        throwsFormatException,
      );
    });
  });

  test('readWholeNumbers property keeps every number of a list in order', () {
    forAll(
      (random) => List.generate(
        integerBetween(random, 0, 5),
        (index) => integerBetween(random, -99, 9999),
      ),
      (numbers) {
        expect(
          readWholeNumbers(<String, Object?>{'list': numbers}, 'list'),
          numbers,
        );
        expect(
          () => readWholeNumbers(<String, Object?>{
            'list': <Object?>[...numbers, 'seven'],
          }, 'list'),
          throwsFormatException,
        );
        expect(
          () => readWholeNumbers(<String, Object?>{'list': 3}, 'list'),
          throwsFormatException,
        );
      },
    );
  });

  test('asObject property accepts decoded objects only', () {
    forAll(wordOf, (key) {
      expect(asObject(<String, Object?>{key: 1}), <String, Object?>{key: 1});
      expect(() => asObject(<Object?>[key]), throwsFormatException);
    });
  });
}
