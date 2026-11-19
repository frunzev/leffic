import 'package:flutter/material.dart';

import '../../shared/design/button_look.dart';
import '../../shared/design/design_button.dart';
import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';
import '../../shared/design/icons/design_icon.dart';
import '../../shared/design/icons/design_icons.dart';

const double _headMinimumHeight = 52;

class AskPanelHead extends StatelessWidget {
  const AskPanelHead({required this.onClose, super.key});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: _headMinimumHeight),
      padding: const EdgeInsets.only(left: Spacing.step4, right: Spacing.step2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Row(
        spacing: Spacing.step2,
        children: [
          DesignIcon(
            DesignIcons.chatHeader,
            size: IconSizes.small,
            color: colors.brand,
          ),
          Expanded(
            child: Text(
              'Ask',
              style: textStyleForSize(TextSizes.small)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          DesignIconButton(
            icon: DesignIcons.closePlain,
            semanticLabel: 'Close Ask',
            onPressed: onClose,
            variant: ButtonVariant.quiet,
          ),
        ],
      ),
    );
  }
}
