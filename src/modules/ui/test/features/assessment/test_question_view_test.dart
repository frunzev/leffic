import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/assessment/question_heading.dart';
import 'package:leffic/features/assessment/test_card.dart';
import 'package:leffic/features/assessment/test_question_view.dart';
import 'package:leffic/shared/design/button_look.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/meter.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import 'assessment_generators.dart';
import 'assessment_session_harness.dart';

const double _blockGap = 16;
const double _questionToOptions = 24;

typedef _QuestionCalls = List<String>;

DesignButton _buttonLabelled(WidgetTester tester, String label) {
  return tester.widget<DesignButton>(find.widgetWithText(DesignButton, label));
}

Widget _questionViewOf({
  required int position,
  required int totalItems,
  required _QuestionCalls calls,
  required bool isEditable,
}) {
  final item = multipleChoiceItem(id: position, optionCount: 3);

  return hostedPlainly(
    Center(
      child: SizedBox(
        width: 720,
        child: TestQuestionView(
          item: item,
          chosenAnswers: const [],
          position: position,
          totalItems: totalItems,
          onChoose: (answer) => calls.add('choose'),
          onEdit: isEditable ? () => calls.add('edit') : null,
          onBack: position > 1 ? () => calls.add('back') : null,
          onNext: () => calls.add('next'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('TestQuestionView property offers Finish on the last question', (
    tester,
  ) async {
    useDesktopSurface(tester);

    final examples = examplesOf((random) {
      final totalItems = integerBetween(random, 2, 30);

      return (integerBetween(random, 2, totalItems), totalItems);
    }, runs: 8);

    for (final (position, totalItems) in examples) {
      final calls = <String>[];

      await tester.pumpWidget(
        _questionViewOf(
          position: position,
          totalItems: totalItems,
          calls: calls,
          isEditable: true,
        ),
      );

      final nextLabel = position >= totalItems ? 'Finish' : 'Next';

      expect(find.text('Question $position?'), findsOneWidget);

      await tester.tap(find.text('Option $position-0'));
      await tester.tap(questionActionsButton());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit question'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back'));
      await tester.tap(find.text(nextLabel));

      expect(calls, ['choose', 'edit', 'back', 'next']);
    }
  });

  testWidgets('TestQuestionView property hides what it cannot do', (
    tester,
  ) async {
    useDesktopSurface(tester);

    await tester.pumpWidget(
      _questionViewOf(position: 1, totalItems: 2, calls: [], isEditable: false),
    );

    expect(_buttonLabelled(tester, 'Back').onPressed, isNull);
    expect(questionActionsButton(), findsNothing);
  });

  testWidgets('TestQuestionView property stacks meter, card and nav', (
    tester,
  ) async {
    useDesktopSurface(tester);

    final examples = examplesOf((random) {
      final totalItems = integerBetween(random, 1, 30);

      return (integerBetween(random, 1, totalItems), totalItems);
    }, runs: 6);

    for (final (position, totalItems) in examples) {
      await tester.pumpWidget(
        _questionViewOf(
          position: position,
          totalItems: totalItems,
          calls: [],
          isEditable: true,
        ),
      );

      final nextLabel = position >= totalItems ? 'Finish' : 'Next';
      final meter = tester.getRect(find.byType(MeterBlock));
      final card = tester.getRect(find.byType(TestCard));
      final heading = tester.getRect(find.byType(QuestionHeading));
      final firstOption = tester.getRect(find.text('Option $position-0'));
      final back = tester.getRect(find.widgetWithText(DesignButton, 'Back'));
      final next = tester.getRect(find.widgetWithText(DesignButton, nextLabel));

      expect(card.top, meter.bottom + _blockGap);
      expect(back.top, card.bottom + _blockGap);
      expect(meter.left, card.left);
      expect(meter.right, card.right);
      expect(back.left, card.left);
      expect(next.right, card.right);
      expect(next.top, back.top);
      expect(
        firstOption.top,
        greaterThanOrEqualTo(heading.bottom + _questionToOptions),
      );
      expect(_buttonLabelled(tester, 'Back').variant, ButtonVariant.standard);
      expect(_buttonLabelled(tester, nextLabel).variant, ButtonVariant.primary);
    }
  });
}
