import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/assessment/answer_row.dart';
import 'package:leffic/features/assessment/edited_test_item.dart';
import 'package:leffic/features/assessment/test_item_editor_dialog.dart';
import 'package:leffic/shared/design/choice_marks.dart';
import 'package:leffic/shared/design/design_field.dart';
import 'package:leffic/shared/design/design_modal.dart';
import 'package:leffic/shared/design/design_text_field.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import 'assessment_generators.dart';

Future<List<Object?>> _openEditor(WidgetTester tester, int optionCount) async {
  final answers = <Object?>[];
  final item = multipleChoiceItem(id: 5, optionCount: optionCount);

  await tester.pumpWidget(
    hostedPlainly(
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => answers.add(
            await showTestItemEditor(context: context, item: item),
          ),
          child: const Text('open dialog'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open dialog'));
  await tester.pumpAndSettle();

  return answers;
}

Finder _answerField(int index) {
  return find.descendant(
    of: find.byType(AnswerRow).at(index),
    matching: find.byType(TextField),
  );
}

Finder _questionField() {
  return find.descendant(
    of: find.widgetWithText(DesignField, 'Question'),
    matching: find.byType(TextField),
  );
}

void main() {
  testWidgets('showTestItemEditor property answers the edited question', (
    tester,
  ) async {
    useDesktopSurface(tester);

    final examples = examplesOf((random) {
      final optionCount = integerBetween(random, 2, 4);

      return (
        optionCount,
        generatedQuestion(random),
        wordOf(random),
        integerBetween(random, 0, optionCount - 1),
      );
    }, runs: 6);

    for (final (optionCount, question, answerText, correctIndex) in examples) {
      final answers = await _openEditor(tester, optionCount);

      await tester.enterText(_questionField(), question);
      await tester.enterText(_answerField(correctIndex), answerText);
      await tester.tap(find.byType(DesignRadio<int>).at(correctIndex));
      await tester.pump();
      await tester.tap(find.text('Save question'));
      await tester.pumpAndSettle();

      final edited = answers.single! as EditedTestItem;

      expect(edited.question, question);
      expect(edited.correctAnswer, answerText);
      expect(edited.wrongAnswers.length, optionCount - 1);
    }
  });

  testWidgets('TestItemEditorDialog property starts on the correct option', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final optionCount in examplesOf(
      (random) => integerBetween(random, 2, 5),
      runs: 4,
    )) {
      final answers = await _openEditor(tester, optionCount);

      await tester.tap(find.text('Save question'));
      await tester.pumpAndSettle();

      final edited = answers.single! as EditedTestItem;

      expect(edited.correctAnswer, 'Option 5-0');
      expect(edited.question, 'Question 5?');
    }
  });

  testWidgets('TestItemEditorDialog property adds and removes answers', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final (addedText, removedIndex) in examplesOf(
      (random) => (wordOf(random), integerBetween(random, 1, 2)),
      runs: 4,
    )) {
      final answers = await _openEditor(tester, 3);

      await tester.tap(find.text('Add answer'));
      await tester.pump();
      await tester.enterText(_answerField(3), addedText);
      await tester.tap(
        find.bySemanticsLabel('Remove answer ${removedIndex + 1}'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save question'));
      await tester.pumpAndSettle();

      final edited = answers.single! as EditedTestItem;

      expect(edited.correctAnswer, 'Option 5-0');
      expect(edited.wrongAnswers, contains(addedText));
      expect(edited.wrongAnswers, isNot(contains('Option 5-$removedIndex')));
      expect(edited.wrongAnswers.length, 2);
    }
  });

  testWidgets('TestItemEditorDialog property is the wide .modal of edits', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final optionCount in examplesOf(
      (random) => integerBetween(random, 2, 5),
      runs: 3,
    )) {
      await _openEditor(tester, optionCount);

      final modal = tester.widget<DesignModal>(find.byType(DesignModal));
      final questionArea = tester.widget<DesignTextArea>(
        find.byType(DesignTextArea),
      );
      final questionField = tester.getRect(
        find.widgetWithText(DesignField, 'Question'),
      );
      final legend = tester.getRect(find.text('Answers'));

      expect(modal.title, 'Edit question');
      expect(
        modal.description,
        'Changes apply the next time this question comes up.',
      );
      expect(modal.width, ModalWidth.wide);
      expect(questionArea.rows, 3);
      expect(tester.getSize(find.byType(DesignTextArea)).height, 132);
      expect(legend.top, questionField.bottom + 16);
      expect(find.byType(AnswerRow), findsNWidgets(optionCount));

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('TestItemEditorDialog property refuses a blank answer', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final blank in examplesOf(
      (random) => ' ' * random.nextInt(3),
      runs: 3,
    )) {
      final answers = await _openEditor(tester, 2);

      await tester.enterText(_answerField(1), blank);
      await tester.pump();
      await tester.tap(find.text('Save question'));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(answers, [null]);
    }
  });
}
