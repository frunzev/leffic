import 'package:flutter/material.dart';

import '../design/design_field.dart';
import '../design/design_text_field.dart';

class SourceFieldCopy {
  const SourceFieldCopy({
    required this.label,
    required this.placeholder,
    required this.hint,
    required this.keyboardType,
  });

  final String label;
  final String placeholder;
  final String hint;
  final TextInputType keyboardType;
}

const SourceFieldCopy linkFieldCopy = SourceFieldCopy(
  label: 'Page address',
  placeholder: 'https://',
  hint: 'Leffic reads the page and uses only what is on it.',
  keyboardType: TextInputType.url,
);

const SourceFieldCopy topicFieldCopy = SourceFieldCopy(
  label: 'Topic',
  placeholder: 'e.g. Action potentials',
  hint: 'Leffic writes the material itself, so keep the topic specific.',
  keyboardType: TextInputType.text,
);

class SourceTextPanel extends StatelessWidget {
  const SourceTextPanel({
    required this.copy,
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final SourceFieldCopy copy;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DesignField(
      label: copy.label,
      hint: copy.hint,
      input: DesignTextField(
        controller: controller,
        placeholder: copy.placeholder,
        keyboardType: copy.keyboardType,
        onChanged: onChanged,
      ),
    );
  }
}
