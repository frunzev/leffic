import 'package:flutter/material.dart';

import '../design/design_field.dart';
import '../design/design_text_field.dart';
import 'generation_choices.dart';
import 'generation_choices_section.dart';

const int _textRows = 8;
const double _textMinimumHeight = 176;

class TextAndChoices extends StatelessWidget {
  const TextAndChoices({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onTyped,
    required this.choices,
    required this.onChoicesChanged,
    super.key,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onTyped;
  final GenerationChoices choices;
  final ValueChanged<GenerationChoices> onChoicesChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignField(
          label: label,
          hint: hint,
          input: DesignTextArea(
            controller: controller,
            onChanged: onTyped,
            rows: _textRows,
            minimumHeight: _textMinimumHeight,
          ),
        ),
        GenerationChoicesSection(choices: choices, onChanged: onChoicesChanged),
      ],
    );
  }
}
