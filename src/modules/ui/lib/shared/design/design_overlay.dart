import 'package:flutter/material.dart';

import 'button_look.dart';
import 'design_button.dart';
import 'design_colors.dart';
import 'design_metrics.dart';
import 'design_typography.dart';
import 'icons/design_icons.dart';

const double _barHeight = 52;
const double _barBorderWidth = 1;

class DesignOverlay extends StatelessWidget {
  const DesignOverlay({
    required this.title,
    required this.closeLabel,
    required this.onClose,
    required this.child,
    super.key,
  });

  final String title;
  final String closeLabel;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return ColoredBox(
      color: colors.surfaceSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: _barHeight),
            padding: const EdgeInsets.fromLTRB(
              Spacing.step4,
              0,
              Spacing.step3,
              0,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                bottom: BorderSide(color: colors.line, width: _barBorderWidth),
              ),
            ),
            child: Row(
              spacing: Spacing.step3,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: textStyleForSize(TextSizes.small)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                DesignIconButton(
                  icon: DesignIcons.closePlain,
                  semanticLabel: closeLabel,
                  variant: ButtonVariant.quiet,
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
