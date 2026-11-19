import 'package:flutter/material.dart';

import '../../shared/design/button_look.dart';
import '../../shared/design/design_button.dart';
import '../../shared/design/design_field.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_modal.dart';
import '../../shared/design/design_text_field.dart';
import 'answer_fieldset.dart';
import 'assessment_models.dart';
import 'edited_test_item.dart';

Future<EditedTestItem?> showTestItemEditor({
  required BuildContext context,
  required TestItem item,
}) {
  return showDesignModal<EditedTestItem>(
    context: context,
    builder: (context) => TestItemEditorDialog(item: item),
  );
}

List<TextEditingController> _answerControllersFor(List<TestOption> options) {
  final controllers = <TextEditingController>[];

  for (final option in options) {
    controllers.add(TextEditingController(text: option.text));
  }

  return controllers;
}

class TestItemEditorDialog extends StatefulWidget {
  const TestItemEditorDialog({required this.item, super.key});

  final TestItem item;

  @override
  State<TestItemEditorDialog> createState() => _TestItemEditorDialogState();
}

class _TestItemEditorDialogState extends State<TestItemEditorDialog> {
  late final TextEditingController _question = TextEditingController(
    text: widget.item.question,
  );
  late List<TextEditingController> _answers = _answerControllersFor(
    widget.item.options,
  );
  late int _correctIndex = initialCorrectIndex(widget.item.options);

  List<String> _answerTexts() {
    final texts = <String>[];

    for (final answer in _answers) {
      texts.add(answer.text);
    }

    return texts;
  }

  void _refreshSaveButton() {
    setState(() {});
  }

  void _addAnswer() {
    setState(() => _answers = [..._answers, TextEditingController()]);
  }

  void _removeAnswer(int index) {
    final removedAnswer = _answers[index];
    final remainingAnswers = List.of(_answers)..removeAt(index);

    setState(() {
      _answers = remainingAnswers;
      _correctIndex = correctIndexAfterRemoval(
        correctIndex: _correctIndex,
        removedIndex: index,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) => removedAnswer.dispose(),
    );
  }

  void _markCorrect(int index) {
    setState(() => _correctIndex = index);
  }

  void _save() {
    final edited = EditedTestItem.fromAnswers(
      question: _question.text,
      answers: _answerTexts(),
      correctIndex: _correctIndex,
    );

    Navigator.of(context).pop(edited);
  }

  @override
  void dispose() {
    _question.dispose();

    for (final answer in _answers) {
      answer.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncomplete = isDraftIncomplete(
      question: _question.text,
      answers: _answerTexts(),
    );

    return DesignModal(
      title: 'Edit question',
      description: 'Changes apply the next time this question comes up.',
      width: ModalWidth.wide,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.step4,
        children: [
          DesignField(
            label: 'Question',
            input: DesignTextArea(
              controller: _question,
              onChanged: (text) => _refreshSaveButton(),
            ),
          ),
          AnswerFieldset(
            answers: _answers,
            correctIndex: _correctIndex,
            onMarkCorrect: _markCorrect,
            onRemove: _removeAnswer,
            onAdd: _addAnswer,
            onChanged: _refreshSaveButton,
          ),
        ],
      ),
      actions: [
        DesignButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DesignButton(
          label: 'Save question',
          variant: ButtonVariant.primary,
          onPressed: isIncomplete ? null : _save,
        ),
      ],
    );
  }
}
