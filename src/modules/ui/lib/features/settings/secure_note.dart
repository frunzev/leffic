import 'package:flutter/material.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';
import '../../shared/design/icons/design_icon.dart';
import '../../shared/design/icons/design_icons.dart';
import '../../shared/design/inset_block.dart';

class SecureNote extends StatelessWidget {
  const SecureNote({
    required this.icon,
    required this.iconColor,
    required this.children,
    super.key,
  });

  final DesignIcons icon;
  final Color iconColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return InsetBlock(
      child: DefaultTextStyle.merge(
        style: textStyleForSize(TextSizes.small)
            .copyWith(color: colors.inkSecondary),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spacing.step3,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: Spacing.step1),
              child: DesignIcon(icon, size: IconSizes.small, color: iconColor),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Spacing.step2,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
