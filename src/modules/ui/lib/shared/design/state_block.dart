import 'package:flutter/material.dart';

import 'design_colors.dart';
import 'design_metrics.dart';
import 'design_typography.dart';
import 'icons/design_icon.dart';
import 'icons/design_icons.dart';

const double _stateIconSize = 32;
const int _textMeasureCharacters = 44;

class StateBlock extends StatelessWidget {
  const StateBlock({
    required this.title,
    this.icon,
    this.text,
    this.action,
    super.key,
  });

  final String title;
  final DesignIcons? icon;
  final String? text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);
    final stateIcon = icon;
    final stateText = text;
    final stateAction = action;
    final textWidth = widthOfCharacters(
      _textMeasureCharacters,
      textSize: TextSizes.small,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.step8,
        horizontal: Spacing.step5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: Spacing.step3,
        children: [
          if (stateIcon != null)
            DesignIcon(
              stateIcon,
              size: _stateIconSize,
              color: colors.inkTertiary,
            ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textStyleForSize(TextSizes.large)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          if (stateText != null)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: textWidth),
              child: Text(
                stateText,
                textAlign: TextAlign.center,
                style: textStyleForSize(TextSizes.small)
                    .copyWith(color: colors.inkSecondary),
              ),
            ),
          if (stateAction != null)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.step2),
              child: stateAction,
            ),
        ],
      ),
    );
  }
}
