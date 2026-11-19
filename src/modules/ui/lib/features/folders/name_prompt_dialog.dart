import 'package:flutter/widgets.dart';

import '../../shared/design/button_look.dart';
import '../../shared/design/design_button.dart';
import '../../shared/design/design_field.dart';
import '../../shared/design/design_modal.dart';
import '../../shared/design/design_text_field.dart';

@immutable
class NamePrompt {
  const NamePrompt({
    required this.title,
    required this.fieldLabel,
    required this.confirmLabel,
    this.description,
    this.placeholder = '',
    this.initialName = '',
  });

  final String title;
  final String fieldLabel;
  final String confirmLabel;
  final String? description;
  final String placeholder;
  final String initialName;
}

Future<String?> showNamePrompt({
  required BuildContext context,
  required NamePrompt prompt,
}) {
  return showDesignModal<String>(
    context: context,
    builder: (context) => NamePromptDialog(prompt: prompt),
  );
}

class NamePromptDialog extends StatefulWidget {
  const NamePromptDialog({required this.prompt, super.key});

  final NamePrompt prompt;

  @override
  State<NamePromptDialog> createState() => _NamePromptDialogState();
}

class _NamePromptDialogState extends State<NamePromptDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.prompt.initialName,
  );

  String get _trimmedName => _name.text.trim();

  void _refreshConfirmButton(String typedName) {
    setState(() {});
  }

  void _confirm() {
    if (_trimmedName.isEmpty) {
      return;
    }

    Navigator.of(context).pop(_trimmedName);
  }

  void _submit(String typedName) {
    _confirm();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prompt = widget.prompt;
    final isBlank = _trimmedName.isEmpty;

    return DesignModal(
      title: prompt.title,
      description: prompt.description,
      body: DesignField(
        label: prompt.fieldLabel,
        input: DesignTextField(
          controller: _name,
          placeholder: prompt.placeholder,
          initialFocus: InitialFocus.focused,
          onChanged: _refreshConfirmButton,
          onSubmitted: _submit,
        ),
      ),
      actions: [
        DesignButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DesignButton(
          label: prompt.confirmLabel,
          variant: ButtonVariant.primary,
          onPressed: isBlank ? null : _confirm,
        ),
      ],
    );
  }
}
