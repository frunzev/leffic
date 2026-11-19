import 'package:flutter/material.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';
import '../../shared/design/icons/design_icon.dart';
import '../../shared/design/icons/design_icons.dart';

const double _barHeight = 52;

class FileBar extends StatelessWidget {
  const FileBar({
    required this.fileName,
    this.details = const [],
    this.tools = const [],
    this.actions = const [],
    super.key,
  });

  final String fileName;
  final List<Widget> details;
  final List<Widget> tools;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: _barHeight),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.step4),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: Spacing.step3,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: Spacing.step3,
              children: [
                DesignIcon(DesignIcons.file, color: colors.inkTertiary),
                Flexible(
                  child: Text(
                    fileName,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: textStyleForSize(TextSizes.small)
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                ...details,
              ],
            ),
          ),
          if (tools.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: Spacing.step3,
              children: tools,
            ),
          if (actions.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: Spacing.step2,
              children: actions,
            ),
        ],
      ),
    );
  }
}
