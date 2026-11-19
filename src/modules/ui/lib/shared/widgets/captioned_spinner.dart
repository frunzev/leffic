import 'package:flutter/material.dart';

import '../design/design_colors.dart';
import '../design/design_metrics.dart';
import '../design/design_typography.dart';
import '../design/spinner.dart';

class CaptionedSpinner extends StatelessWidget {
  const CaptionedSpinner({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: Spacing.step3,
        children: [
          const Spinner(),
          Text(
            label,
            style: textStyleForSize(TextSizes.small)
                .copyWith(color: DesignColors.of(context).inkSecondary),
          ),
        ],
      ),
    );
  }
}
