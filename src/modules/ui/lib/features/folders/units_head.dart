import 'package:flutter/widgets.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';
import '../../shared/design/section_label.dart';
import 'unit_presentation.dart';

const String _orderNote = 'Newest first';

class UnitsHead extends StatelessWidget {
  const UnitsHead({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final noteStyle = textStyleForSize(TextSizes.small)
        .copyWith(color: DesignColors.of(context).inkTertiary);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      spacing: Spacing.step4,
      children: [
        SectionLabel(itemCountLabel(count)),
        Text(_orderNote, style: noteStyle),
      ],
    );
  }
}
