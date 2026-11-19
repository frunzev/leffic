import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/assessment/test_answer.dart';

import '../../support/property.dart';

Object _generatedWireValue(Random random) {
  if (random.nextBool()) {
    return integerBetween(random, 0, 9);
  }

  return anyTextOf(random);
}

List<Object> _generatedWireValues(Random random) {
  final count = integerBetween(random, 0, 4);
  final values = <Object>[];

  for (var index = 0; index < count; index++) {
    values.add(_generatedWireValue(random));
  }

  return values;
}

List<TestAnswer> _answersOf(List<Object> wireValues) {
  final answers = <TestAnswer>[];

  for (final wireValue in wireValues) {
    answers.add(TestAnswer.fromWire(wireValue));
  }

  return answers;
}

void main() {
  test('TestAnswer.fromWire property round-trips the wire value', () {
    forAll(_generatedWireValue, (wireValue) {
      final answer = TestAnswer.fromWire(wireValue);

      expect(answer.wireValue, wireValue);
      expect(
        answer,
        wireValue is int ? isA<ChosenOption>() : isA<TypedAnswer>(),
      );
    });
  });

  test('TestAnswer.fromWire property refuses anything else', () {
    forAll(
      (random) => oneOf<Object?>(random, [null, 1.5, true, <Object?>[], {}]),
      (wireValue) {
        expect(() => TestAnswer.fromWire(wireValue), throwsFormatException);
      },
    );
  });

  test('readTestAnswers property reads stored answers in order', () {
    forAll(_generatedWireValues, (wireValues) {
      final answers = readTestAnswers({
        'last_answers': wireValues,
      }, 'last_answers');
      final readValues = <Object>[];

      for (final answer in answers) {
        readValues.add(answer.wireValue);
      }

      expect(readValues, wireValues);
    });
  });

  test('readTestAnswers property reads nothing stored as no answers', () {
    forAll(wordOf, (key) {
      expect(readTestAnswers({key: null}, key), isEmpty);
      expect(readTestAnswers({}, key), isEmpty);
    });
  });

  test('readTestAnswers property refuses a value that is no list', () {
    forAll(wordOf, (key) {
      expect(() => readTestAnswers({key: 'text'}, key), throwsFormatException);
    });
  });

  test('isOptionChosen property finds exactly the chosen option ids', () {
    forAll(
      (random) => (_generatedWireValues(random), integerBetween(random, 0, 9)),
      (example) {
        final (wireValues, optionId) = example;

        expect(
          isOptionChosen(_answersOf(wireValues), optionId),
          wireValues.contains(optionId),
        );
      },
    );
  });

  test('typedTextOf property is the first typed answer or nothing', () {
    forAll(_generatedWireValues, (wireValues) {
      var expected = '';

      for (final wireValue in wireValues) {
        if (wireValue is String) {
          expected = wireValue;
          break;
        }
      }

      expect(typedTextOf(_answersOf(wireValues)), expected);
    });
  });
}
