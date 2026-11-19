import 'package:flutter/material.dart';

import 'design_colors.dart';
import 'design_metrics.dart';

const EdgeInsets _insetPadding = EdgeInsets.symmetric(
  vertical: Spacing.step3,
  horizontal: Spacing.step4,
);

class InsetBlock extends StatelessWidget {
  const InsetBlock({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return Container(
      padding: _insetPadding,
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(Radii.medium),
      ),
      child: child,
    );
  }
}
