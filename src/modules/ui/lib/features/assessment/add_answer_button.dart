import 'package:flutter/material.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';
import '../../shared/design/focus_outline.dart';
import '../../shared/design/icons/design_icon.dart';
import '../../shared/design/icons/design_icons.dart';
import '../../shared/design/pressable.dart';

const double _addMinimumHeight = 44;

class AddAnswerButton extends StatelessWidget {
  const AddAnswerButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  Widget _buildFace(BuildContext context, InteractionState state) {
    final colors = DesignColors.of(context);

    return FocusOutline(
      state: state,
      borderRadius: 0,
      child: Container(
        constraints: const BoxConstraints(minHeight: _addMinimumHeight),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.step4),
        color: state.isHovered ? colors.hover : null,
        child: Row(
          spacing: Spacing.step3,
          children: [
            DesignIcon(
              DesignIcons.plus,
              size: IconSizes.small,
              color: colors.brand,
            ),
            Text(
              'Add answer',
              style: textStyleForSize(TextSizes.small)
                  .copyWith(color: colors.brand, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(onPressed: onPressed, builder: _buildFace);
  }
}
