import 'package:flutter/material.dart';

import 'design_colors.dart';
import 'design_metrics.dart';
import 'design_typography.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: textStyleForSize(TextSizes.small).copyWith(
        color: DesignColors.of(context).inkSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
