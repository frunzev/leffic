import 'package:flutter/material.dart';

import 'design_colors.dart';
import 'design_metrics.dart';
import 'design_typography.dart';

const Key _fillKey = ValueKey('meter fill');

class Meter extends StatelessWidget {
  const Meter({required this.fraction, super.key});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    if (fraction < 0 || fraction > 1) {
      throw ArgumentError.value(fraction, 'fraction', 'must be within 0..1');
    }

    final colors = DesignColors.of(context);
    final pill = BorderRadius.circular(Radii.pill);

    return SizedBox(
      height: LayoutSizes.meterHeight,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceTertiary,
          borderRadius: pill,
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: fraction,
          child: DecoratedBox(
            key: _fillKey,
            decoration: BoxDecoration(color: colors.brand, borderRadius: pill),
          ),
        ),
      ),
    );
  }
}

class MeterBlock extends StatelessWidget {
  const MeterBlock({
    required this.startLabel,
    required this.endLabel,
    required this.fraction,
    super.key,
  });

  final String startLabel;
  final String endLabel;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final legendStyle = textStyleForSize(TextSizes.small).copyWith(
      color: DesignColors.of(context).inkTertiary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spacing.step2,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          spacing: Spacing.step4,
          children: [
            Text(startLabel, style: legendStyle),
            Text(endLabel, style: legendStyle),
          ],
        ),
        Meter(fraction: fraction),
      ],
    );
  }
}
