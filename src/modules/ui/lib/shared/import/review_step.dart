import 'package:flutter/material.dart';

import '../design/design_colors.dart';
import '../design/design_metrics.dart';
import '../design/design_typography.dart';
import '../design/icons/design_icon.dart';
import '../design/icons/design_icons.dart';
import 'generation_choices.dart';
import 'text_and_choices.dart';

const String _reviewLabel = 'Extracted text';
const String _reviewHint =
    'Trim anything that should not become study material.';

class ReviewSourceLine extends StatelessWidget {
  const ReviewSourceLine({required this.sourceLabel, super.key});

  final String sourceLabel;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return Row(
      spacing: Spacing.step2,
      children: [
        DesignIcon(
          DesignIcons.file,
          size: IconSizes.small,
          color: colors.inkTertiary,
        ),
        Flexible(
          child: Text(
            'From $sourceLabel',
            style: textStyleForSize(TextSizes.small)
                .copyWith(color: colors.inkSecondary),
          ),
        ),
      ],
    );
  }
}

class ReviewStep extends StatelessWidget {
  const ReviewStep({
    required this.sourceLabel,
    required this.controller,
    required this.onTyped,
    required this.choices,
    required this.onChoicesChanged,
    super.key,
  });

  final String sourceLabel;
  final TextEditingController controller;
  final ValueChanged<String> onTyped;
  final GenerationChoices choices;
  final ValueChanged<GenerationChoices> onChoicesChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spacing.step4,
      children: [
        ReviewSourceLine(sourceLabel: sourceLabel),
        TextAndChoices(
          label: _reviewLabel,
          hint: _reviewHint,
          controller: controller,
          onTyped: onTyped,
          choices: choices,
          onChoicesChanged: onChoicesChanged,
        ),
      ],
    );
  }
}
