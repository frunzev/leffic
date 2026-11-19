import 'package:flutter/material.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';
import 'ruled_block.dart';

class ComponentRow extends StatelessWidget {
  const ComponentRow({
    required this.title,
    required this.description,
    this.actions = const [],
    this.details = const [],
    super.key,
  });

  final String title;
  final String description;
  final List<Widget> actions;
  final List<Widget> details;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return RuledBlock(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.step3,
        children: [
          Row(
            spacing: Spacing.step3,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Spacing.step1,
                  children: [
                    Text(
                      title,
                      style: textStyleForSize(TextSizes.medium)
                          .copyWith(color: colors.ink),
                    ),
                    Text(
                      description,
                      style: textStyleForSize(TextSizes.small)
                          .copyWith(color: colors.inkTertiary),
                    ),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
          ...details,
        ],
      ),
    );
  }
}
