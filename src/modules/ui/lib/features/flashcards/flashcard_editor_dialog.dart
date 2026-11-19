import 'package:flutter/material.dart';

import '../../shared/design/button_look.dart';
import '../../shared/design/design_button.dart';
import '../../shared/design/design_field.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_modal.dart';
import '../../shared/design/design_text_field.dart';
import 'face_editing.dart';
import 'flashcard_faces.dart';

Future<FlashcardFace?> showFlashcardEditor({
  required BuildContext context,
  required FlashcardFace face,
}) {
  return showDesignModal<FlashcardFace>(
    context: context,
    builder: (context) => FlashcardEditorDialog(face: face),
  );
}

class FlashcardEditorDialog extends StatefulWidget {
  const FlashcardEditorDialog({required this.face, super.key});

  final FlashcardFace face;

  @override
  State<FlashcardEditorDialog> createState() => _FlashcardEditorDialogState();
}

class _FlashcardEditorDialogState extends State<FlashcardEditorDialog> {
  late final FaceFields _fields = editableFieldsOf(widget.face);
  late final TextEditingController _firstText = TextEditingController(
    text: _fields.firstText,
  );
  late final TextEditingController _secondText = TextEditingController(
    text: _fields.secondText,
  );

  FlashcardFace _editedFace() {
    return faceEditedWith(
      widget.face,
      firstText: _firstText.text,
      secondText: _secondText.text,
    );
  }

  void _save() {
    Navigator.of(context).pop(_editedFace());
  }

  void _refreshSaveButton(String text) {
    setState(() {});
  }

  @override
  void dispose() {
    _firstText.dispose();
    _secondText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncomplete = _editedFace().isIncomplete;

    return DesignModal(
      title: 'Edit flashcard',
      description: 'Changes apply the next time this card comes up.',
      width: ModalWidth.wide,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.step4,
        children: [
          DesignField(
            label: _fields.firstLabel,
            input: DesignTextArea(
              controller: _firstText,
              onChanged: _refreshSaveButton,
            ),
          ),
          DesignField(
            label: _fields.secondLabel,
            input: DesignTextArea(
              controller: _secondText,
              onChanged: _refreshSaveButton,
            ),
          ),
        ],
      ),
      actions: [
        DesignButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DesignButton(
          label: 'Save card',
          variant: ButtonVariant.primary,
          onPressed: isIncomplete ? null : _save,
        ),
      ],
    );
  }
}
