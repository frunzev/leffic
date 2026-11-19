import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/assessment/answer_choices.dart';
import 'package:leffic/features/assessment/answer_option_button.dart';
import 'package:leffic/features/assessment/assessment_models.dart';
import 'package:leffic/features/assessment/question_meter.dart';
import 'package:leffic/features/assessment/test_answer.dart';
import 'package:leffic/features/assessment/typed_answer_field.dart';
import 'package:leffic/shared/design/meter.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

const String _letters = 'ABCDEFGH';
const double _optionGap = 8;

AnswerOptionButton _optionButton(WidgetTester tester, String text) {
  return tester.widget<AnswerOptionButton>(
    find.ancestor(
      of: find.text(text),
      matching: find.byType(AnswerOptionButton),
    ),
  );
}

TestItem _multipleChoiceItem(int optionCount) {
  final options = <Object?>[];

  for (var optionId = 0; optionId < optionCount; optionId++) {
    options.add({'id': optionId, 'option': 'Option $optionId'});
  }

  return TestItem.fromJson({
    'id': 7,
    'type': 'multiple_choice',
    'content': {'question': 'Question 7?', 'shuffled_options': options},
    'last_answers': null,
  });
}

void main() {
  test('optionLetter property letters the first eight, then numbers', () {
    forAll((random) => integerBetween(random, 0, 30), (index) {
      final expected = index < _letters.length
          ? _letters[index]
          : '${index + 1}';

      expect(optionLetter(index), expected);
    });
  });

  testWidgets('QuestionMeter property shows the position and what is left', (
    tester,
  ) async {
    final examples = examplesOf((random) {
      final totalItems = integerBetween(random, 1, 40);

      return (integerBetween(random, 1, totalItems), totalItems);
    }, runs: 10);

    for (final (position, totalItems) in examples) {
      await tester.pumpWidget(
        hostedPlainly(
          QuestionMeter(position: position, totalItems: totalItems),
        ),
      );

      final meter = tester.widget<MeterBlock>(find.byType(MeterBlock));

      expect(meter.startLabel, 'Question $position of $totalItems');
      expect(meter.endLabel, '${max(0, totalItems - position)} to go');
      expect(meter.fraction, position / totalItems);
    }
  });

  testWidgets('AnswerChoices property marks the chosen option and letters', (
    tester,
  ) async {
    final examples = examplesOf(
      (random) => (integerBetween(random, 2, 6), integerBetween(random, 0, 5)),
      runs: 8,
    );

    for (final (optionCount, chosenId) in examples) {
      final item = _multipleChoiceItem(optionCount);
      final chosen = <TestAnswer>[];

      await tester.pumpWidget(
        hostedPlainly(
          AnswerChoices(
            item: item,
            chosenAnswers: [ChosenOption(chosenId)],
            onChoose: chosen.add,
          ),
        ),
      );

      for (var index = 0; index < item.options.length; index++) {
        final option = item.options[index];
        final button = _optionButton(tester, option.text);

        expect(button.isChosen, option.id == chosenId);
        expect(button.letter, optionLetter(index));
      }

      await tester.tap(find.text(item.options.last.text));

      expect(chosen.single.wireValue, item.options.last.id);
    }
  });

  testWidgets('AnswerChoices property stacks the options 8 apart', (
    tester,
  ) async {
    for (final optionCount in examplesOf(
      (random) => integerBetween(random, 2, 6),
      runs: 5,
    )) {
      final item = _multipleChoiceItem(optionCount);

      await tester.pumpWidget(
        hostedPlainly(
          AnswerChoices(item: item, chosenAnswers: const [], onChoose: (_) {}),
        ),
      );

      final buttons = find.byType(AnswerOptionButton);

      for (var index = 1; index < optionCount; index++) {
        final above = tester.getRect(buttons.at(index - 1));
        final below = tester.getRect(buttons.at(index));

        expect(below.top, above.bottom + _optionGap);
        expect(below.left, above.left);
        expect(below.width, above.width);
      }
    }
  });

  testWidgets('AnswerChoices property types an answer without options', (
    tester,
  ) async {
    for (final (stored, typed) in examplesOf(
      (random) => (wordOf(random), wordOf(random)),
      runs: 5,
    )) {
      final item = TestItem.fromJson({
        'id': 3,
        'type': 'short_answer',
        'content': {'question': 'Name it', 'shuffled_options': <Object?>[]},
        'last_answers': [stored],
      });
      final chosen = <TestAnswer>[];

      await tester.pumpWidget(
        hostedPlainly(
          AnswerChoices(
            item: item,
            chosenAnswers: item.lastAnswers,
            onChoose: chosen.add,
          ),
        ),
      );

      expect(find.text(stored), findsOneWidget);
      expect(find.byType(AnswerOptionButton), findsNothing);

      await tester.enterText(
        find.descendant(
          of: find.byType(TypedAnswerField),
          matching: find.byType(TextField),
        ),
        typed,
      );

      expect(chosen.last.wireValue, typed);
    }
  });
}
