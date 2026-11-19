import 'package:flutter/material.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';

class RuledBlock extends StatelessWidget {
  const RuledBlock({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: Spacing.step4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: DesignColors.of(context).line)),
      ),
      child: child,
    );
  }
}
