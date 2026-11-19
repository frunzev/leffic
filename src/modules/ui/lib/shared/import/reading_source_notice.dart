import 'package:flutter/material.dart';

import '../design/design_colors.dart';
import '../design/design_metrics.dart';
import '../design/design_typography.dart';
import '../design/spinner.dart';

const String _reviewPromise =
    'You will see the text before anything is generated.';

class ReadingSourceNotice extends StatelessWidget {
  const ReadingSourceNotice({required this.sourceLabel, super.key});

  final String sourceLabel;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.step8,
        horizontal: Spacing.step4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: Spacing.step3,
        children: [
          const Spinner(),
          Text(
            'Reading $sourceLabel…',
            textAlign: TextAlign.center,
            style: textStyleForSize(TextSizes.small)
                .copyWith(color: colors.ink),
          ),
          Text(
            _reviewPromise,
            textAlign: TextAlign.center,
            style: textStyleForSize(TextSizes.extraSmall)
                .copyWith(color: colors.inkTertiary),
          ),
        ],
      ),
    );
  }
}
