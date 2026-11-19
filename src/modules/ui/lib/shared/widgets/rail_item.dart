import 'package:flutter/material.dart';

import '../design/design_colors.dart';
import '../design/design_metrics.dart';
import '../design/design_typography.dart';
import '../design/focus_outline.dart';
import '../design/icons/design_icon.dart';
import '../design/icons/design_icons.dart';
import '../design/pressable.dart';

const Color _transparent = Color(0x00000000);

class RailItem extends StatelessWidget {
  const RailItem({
    required this.icon,
    required this.label,
    required this.isCurrent,
    required this.onPressed,
    super.key,
  });

  final DesignIcons icon;
  final String label;
  final bool isCurrent;
  final VoidCallback onPressed;

  Widget _buildFace(BuildContext context, InteractionState state) {
    final colors = DesignColors.of(context);
    final (fill, ink) = isCurrent
        ? (colors.brandSurfaceStrong, colors.brandStrong)
        : state.isHovered
        ? (colors.hover, colors.ink)
        : (_transparent, colors.inkSecondary);

    return FocusOutline(
      state: state,
      borderRadius: Radii.medium,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(Radii.medium),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: Spacing.step2,
            horizontal: Spacing.step1,
          ),
          child: DefaultTextStyle.merge(
            style: textStyleForSize(TextSizes.extraSmall)
                .copyWith(color: ink, fontWeight: FontWeight.w500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: Spacing.step1,
              children: [DesignIcon(icon), Text(label, maxLines: 1)],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(onPressed: onPressed, builder: _buildFace);
  }
}
