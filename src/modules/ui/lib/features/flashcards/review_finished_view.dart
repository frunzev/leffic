import 'package:flutter/material.dart';

import '../../shared/design/design_button.dart';
import '../../shared/design/icons/design_icons.dart';
import '../../shared/design/state_block.dart';

class ReviewFinishedView extends StatelessWidget {
  const ReviewFinishedView({required this.onBackToFolder, super.key});

  final VoidCallback onBackToFolder;

  @override
  Widget build(BuildContext context) {
    return StateBlock(
      icon: DesignIcons.success,
      title: "You're done for today",
      text:
          'Every card in this deck is scheduled. The next one comes back '
          "when you're about to forget it.",
      action: DesignButton(label: 'Back to folder', onPressed: onBackToFolder),
    );
  }
}
