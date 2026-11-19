import 'package:flutter/material.dart';

import '../design/design_metrics.dart';
import '../design/section_label.dart';
import 'generation_choices.dart';
import 'unit_choice.dart';

const String _heading = 'Generate';

class GenerationChoicesSection extends StatelessWidget {
  const GenerationChoicesSection({
    required this.choices,
    required this.onChanged,
    super.key,
  });

  final GenerationChoices choices;
  final ValueChanged<GenerationChoices> onChanged;

  void _changeFlashcards(GeneratedSetChoice flashcards) {
    onChanged(choices.withFlashcards(flashcards));
  }

  void _changeTest(GeneratedSetChoice test) {
    onChanged(choices.withTest(test));
  }

  void _toggleFlashcards() {
    _changeFlashcards(choices.flashcards.toggled());
  }

  void _toggleTest() {
    _changeTest(choices.test.toggled());
  }

  void _toggleNote() {
    onChanged(choices.withNoteToggled());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: Spacing.step5),
          child: SectionLabel(_heading),
        ),
        const SizedBox(height: Spacing.step3),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Spacing.step4,
          children: [
            UnitChoice(
              name: 'Flashcards',
              hint: 'Recall one fact at a time',
              isChosen: choices.flashcards.isChosen,
              onToggle: _toggleFlashcards,
              chosenOptions: [
                TypeChoiceOptions(
                  options: flashcardTypeOptions,
                  choice: choices.flashcards,
                  onChanged: _changeFlashcards,
                ),
              ],
            ),
            UnitChoice(
              name: 'Test',
              hint: 'Check what stuck',
              isChosen: choices.test.isChosen,
              onToggle: _toggleTest,
              chosenOptions: [
                TypeChoiceOptions(
                  options: testTypeOptions,
                  choice: choices.test,
                  onChanged: _changeTest,
                ),
              ],
            ),
            UnitChoice(
              name: 'Note',
              hint: 'Read it through once',
              isChosen: choices.isNoteChosen,
              onToggle: _toggleNote,
              chosenOptions: const [],
            ),
          ],
        ),
      ],
    );
  }
}
