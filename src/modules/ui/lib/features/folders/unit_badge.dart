import 'package:flutter/widgets.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';

const double _badgeVerticalPadding = 2;
const EdgeInsets _badgePadding = EdgeInsets.symmetric(
  vertical: _badgeVerticalPadding,
  horizontal: Spacing.step2,
);
const BorderRadius _badgeCorners = BorderRadius.all(
  Radius.circular(Radii.pill),
);

class UnitBadge extends StatelessWidget {
  const UnitBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);
    final labelStyle = textStyleForSize(TextSizes.extraSmall)
        .copyWith(color: colors.brandStrong, fontWeight: FontWeight.w600);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.brandSurfaceStrong,
        borderRadius: _badgeCorners,
      ),
      child: Padding(
        padding: _badgePadding,
        child: Text(label, maxLines: 1, softWrap: false, style: labelStyle),
      ),
    );
  }
}
