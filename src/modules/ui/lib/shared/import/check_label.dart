import 'package:flutter/material.dart';

import '../design/choice_marks.dart';
import '../design/design_colors.dart';
import '../design/design_metrics.dart';
import '../design/design_typography.dart';

const double _checkMinimumHeight = 24;

class TappableLabel extends StatelessWidget {
  const TappableLabel({required this.onTap, required this.child, super.key});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class CheckLabel extends StatelessWidget {
  const CheckLabel({
    required this.label,
    required this.isChecked,
    required this.onToggle,
    super.key,
  });

  final String label;
  final bool isChecked;
  final VoidCallback onToggle;

  void _toggle(bool isNowChecked) {
    onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return TappableLabel(
      onTap: onToggle,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _checkMinimumHeight),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: Spacing.step2,
          children: [
            DesignCheckbox(isChecked: isChecked, onChanged: _toggle),
            Flexible(
              child: Text(
                label,
                style: textStyleForSize(TextSizes.small)
                    .copyWith(color: colors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
