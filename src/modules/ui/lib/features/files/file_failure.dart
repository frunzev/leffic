import 'package:flutter/material.dart';

import '../../shared/design/design_button.dart';
import '../../shared/design/icons/design_icons.dart';
import '../../shared/design/state_block.dart';

class FileFailure extends StatelessWidget {
  const FileFailure({
    required this.fileName,
    required this.reason,
    required this.onRetry,
    super.key,
  });

  final String fileName;
  final String reason;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: StateBlock(
        icon: DesignIcons.failure,
        title: "Couldn't open $fileName",
        text: reason,
        action: DesignButton(label: 'Try again', onPressed: onRetry),
      ),
    );
  }
}
