import 'package:flutter/material.dart';

import '../../shared/design/design_button.dart';
import '../../shared/design/icons/design_icons.dart';
import '../../shared/design/state_block.dart';

class EmptyTestView extends StatelessWidget {
  const EmptyTestView({required this.onBackToFolder, super.key});

  final VoidCallback onBackToFolder;

  @override
  Widget build(BuildContext context) {
    return StateBlock(
      icon: DesignIcons.test,
      title: 'This test has no questions yet',
      text:
          'Import a file, a link or a topic into this folder and questions '
          'are generated with it.',
      action: DesignButton(label: 'Back to folder', onPressed: onBackToFolder),
    );
  }
}
