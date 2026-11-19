import 'package:flutter/material.dart';

import '../../shared/design/design_metrics.dart';
import 'answer_option_button.dart';
import 'assessment_models.dart';
import 'test_answer.dart';
import 'typed_answer_field.dart';

const String _optionLetters = 'ABCDEFGH';

String optionLetter(int index) {
  if (index < _optionLetters.length) {
    return _optionLetters[index];
  }

  return '${index + 1}';
}

class AnswerChoices extends StatelessWidget {
  const AnswerChoices({
    required this.item,
    required this.chosenAnswers,
    required this.onChoose,
    super.key,
  });

  final TestItem item;
  final List<TestAnswer> chosenAnswers;
  final ValueChanged<TestAnswer> onChoose;

  Widget _optionButton(int index) {
    final option = item.options[index];

    return AnswerOptionButton(
      letter: optionLetter(index),
      text: option.text,
      isChosen: isOptionChosen(chosenAnswers, option.id),
      onPressed: () => onChoose(ChosenOption(option.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (item.options.isEmpty) {
      return TypedAnswerField(
        key: ValueKey(item.id),
        initialText: typedTextOf(chosenAnswers),
        onChanged: (text) => onChoose(TypedAnswer(text)),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spacing.step2,
      children: [
        for (var index = 0; index < item.options.length; index++)
          _optionButton(index),
      ],
    );
  }
}
