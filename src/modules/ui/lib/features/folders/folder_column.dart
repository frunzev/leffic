import 'package:flutter/widgets.dart';

import '../../shared/design/design_metrics.dart';

const double _folderMaximumWidth = 920;
const EdgeInsets _folderPadding = EdgeInsets.fromLTRB(
  Spacing.step6,
  Spacing.step7,
  Spacing.step6,
  Spacing.step8,
);

class FolderColumn extends StatelessWidget {
  const FolderColumn({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _folderMaximumWidth),
            child: Padding(
              padding: _folderPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Spacing.step6,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
