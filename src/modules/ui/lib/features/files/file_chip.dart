import 'package:flutter/material.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';

const double _chipBlockPadding = 2;

class FileChip extends StatelessWidget {
  const FileChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceTertiary,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: _chipBlockPadding,
          horizontal: Spacing.step2,
        ),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: textStyleForSize(
            TextSizes.extraSmall,
          ).copyWith(color: colors.inkSecondary, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
