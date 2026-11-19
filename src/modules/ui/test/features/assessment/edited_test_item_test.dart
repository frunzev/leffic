import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/assessment/assessment_models.dart';
import 'package:leffic/features/assessment/edited_test_item.dart';

import '../../support/property.dart';
import 'assessment_generators.dart';

typedef _Draft = (String question, List<String> answers, int correctIndex);

_Draft _generatedDraft(Random random) {
  final count = integerBetween(random, 1, 6);
  final answers = <String>[];

  for (var index = 0; index < count; index++) {
    answers.add('  ${wordOf(random)} ');
  }

  return (
    ' ${generatedQuestion(random)} ',
    answers,
    integerBetween(random, 0, count - 1),
  );
}

void main() {
  test('EditedTestItem.fromAnswers property keeps every trimmed answer', () {
    forAll(_generatedDraft, (draft) {
      final (question, answers, correctIndex) = draft;
      final edited = EditedTestItem.fromAnswers(
        question: question,
        answers: answers,
        correctIndex: correctIndex,
      );
      final expectedWrong = <String>[];

      for (var index = 0; index < answers.length; index++) {
        if (index != correctIndex) {
          expectedWrong.add(answers[index].trim());
        }
      }

      expect(edited.question, question.trim());
      expect(edited.correctAnswer, answers[correctIndex].trim());
      expect(edited.wrongAnswers, expectedWrong);
    });
  });

  test('EditedTestItem.toContent property writes a multiple choice item', () {
    forAll(_generatedDraft, (draft) {
      final (question, answers, correctIndex) = draft;
      final edited = EditedTestItem.fromAnswers(
        question: question,
        answers: answers,
        correctIndex: correctIndex,
      );

      expect(edited.toContent(), {
        'question': edited.question,
        'true_option': edited.correctAnswer,
        'false_options': edited.wrongAnswers,
      });
    });
  });

  test('isDraftIncomplete property needs a question and filled answers', () {
    forAll(
      (random) {
        final count = integerBetween(random, 0, 4);
        final answers = <String>[];

        for (var index = 0; index < count; index++) {
          answers.add(oneOf(random, ['', ' ', wordOf(random)]));
        }

        return (oneOf(random, ['', '  ', generatedQuestion(random)]), answers);
      },
      (example) {
        final (question, answers) = example;
        var hasBlankAnswer = false;

        for (final answer in answers) {
          if (answer.trim().isEmpty) {
            hasBlankAnswer = true;
          }
        }

        final expected =
            question.trim().isEmpty || answers.isEmpty || hasBlankAnswer;

        expect(
          isDraftIncomplete(question: question, answers: answers),
          expected,
        );
      },
    );
  });

  test('correctIndexAfterRemoval property keeps pointing at an answer', () {
    forAll(
      (random) {
        final count = integerBetween(random, 2, 8);

        return (
          count,
          integerBetween(random, 0, count - 1),
          integerBetween(random, 0, count - 1),
        );
      },
      (example) {
        final (count, correctIndex, removedIndex) = example;
        final shifted = correctIndexAfterRemoval(
          correctIndex: correctIndex,
          removedIndex: removedIndex,
        );
        final answers = List<int>.generate(count, (index) => index);
        final remaining = List.of(answers)..removeAt(removedIndex);

        expect(shifted, inInclusiveRange(0, count - 2));

        if (removedIndex != correctIndex) {
          expect(remaining[shifted], answers[correctIndex]);
        }
      },
    );
  });

  test('initialCorrectIndex property finds the option with id 0', () {
    forAll((random) => generatedOptionsJson(random, 'multiple_choice'), (
      optionsJson,
    ) {
      final options = [
        for (final json in optionsJson) TestOption.fromJson(json),
      ];
      final correctIndex = initialCorrectIndex(options);

      expect(options[correctIndex].id, 0);
    });
  });

  test('initialCorrectIndex property starts at 0 without a correct one', () {
    forAll((random) => integerBetween(random, 0, 5), (count) {
      final options = [
        for (var id = 1; id <= count; id++)
          TestOption(id: id, text: 'Option $id'),
      ];

      expect(initialCorrectIndex(options), 0);
    });
  });
}
