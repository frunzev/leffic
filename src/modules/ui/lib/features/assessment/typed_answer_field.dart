import 'package:flutter/material.dart';

import '../../shared/design/design_field.dart';
import '../../shared/design/design_text_field.dart';

class TypedAnswerField extends StatefulWidget {
  const TypedAnswerField({
    required this.initialText,
    required this.onChanged,
    super.key,
  });

  final String initialText;
  final ValueChanged<String> onChanged;

  @override
  State<TypedAnswerField> createState() => _TypedAnswerFieldState();
}

class _TypedAnswerFieldState extends State<TypedAnswerField> {
  late final TextEditingController _answer = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesignField(
      label: 'Your answer',
      input: DesignTextField(
        controller: _answer,
        placeholder: 'Type your answer',
        onChanged: widget.onChanged,
      ),
    );
  }
}
