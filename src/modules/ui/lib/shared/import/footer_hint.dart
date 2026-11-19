import 'package:flutter/material.dart';

import '../design/design_colors.dart';
import '../design/design_metrics.dart';
import '../design/design_typography.dart';

class FooterHint extends StatelessWidget {
  const FooterHint({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        style: textStyleForSize(TextSizes.small)
            .copyWith(color: DesignColors.of(context).inkTertiary),
      ),
    );
  }
}
