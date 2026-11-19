import 'package:flutter/material.dart';

import '../../shared/design/button_look.dart';
import '../../shared/design/design_button.dart';
import '../../shared/design/shortcut_chip.dart';

class ShowAnswerButton extends StatelessWidget {
  const ShowAnswerButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DesignButton(
        label: 'Show answer',
        trailing: const ShortcutChip(
          label: 'Space',
          tone: ShortcutChipTone.onBrand,
        ),
        variant: ButtonVariant.primary,
        size: ButtonSize.large,
        onPressed: onPressed,
      ),
    );
  }
}
