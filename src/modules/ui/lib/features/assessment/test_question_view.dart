import 'package:flutter/material.dart';

import '../../shared/design/button_look.dart';
import '../../shared/design/design_button.dart';
import '../../shared/design/design_metrics.dart';
import 'answer_choices.dart';
import 'assessment_models.dart';
import 'question_heading.dart';
import 'question_menu.dart';
import 'question_meter.dart';
import 'test_answer.dart';
import 'test_card.dart';

class TestQuestionView extends StatelessWidget {
  const TestQuestionView({
    required this.item,
    required this.chosenAnswers,
    required this.position,
    required this.totalItems,
    required this.onChoose,
    required this.onEdit,
    required this.onBack,
    required this.onNext,
    super.key,
  });

  final TestItem item;
  final List<TestAnswer> chosenAnswers;
  final int position;
  final int totalItems;
  final ValueChanged<TestAnswer> onChoose;
  final VoidCallback? onEdit;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  String _nextLabel() {
    if (position >= totalItems) {
      return 'Finish';
    }

    return 'Next';
  }

  Widget _questionCard() {
    final editQuestion = onEdit;

    return TestCard(
      menu: editQuestion == null ? null : QuestionMenu(onEdit: editQuestion),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.step5,
        children: [
          QuestionHeading(item.question),
          AnswerChoices(
            item: item,
            chosenAnswers: chosenAnswers,
            onChoose: onChoose,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spacing.step4,
      children: [
        QuestionMeter(position: position, totalItems: totalItems),
        Flexible(child: _questionCard()),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: Spacing.step3,
          children: [
            DesignButton(label: 'Back', onPressed: onBack),
            DesignButton(
              label: _nextLabel(),
              variant: ButtonVariant.primary,
              onPressed: onNext,
            ),
          ],
        ),
      ],
    );
  }
}
