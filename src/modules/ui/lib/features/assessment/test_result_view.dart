import 'package:flutter/material.dart';

import '../../shared/design/balanced_text.dart';
import '../../shared/design/button_look.dart';
import '../../shared/design/design_button.dart';
import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';
import '../../shared/design/section_label.dart';
import 'test_card.dart';

const double _scoreLineHeight = 1;
const double _scoreLetterSpacingInEm = -0.02;
const int _detailMeasureCharacters = 46;

class TestResultView extends StatelessWidget {
  const TestResultView({
    required this.correctCount,
    required this.totalItems,
    required this.missedCount,
    required this.onReviewMissed,
    required this.onRetake,
    required this.onBackToFolder,
    super.key,
  });

  final int correctCount;
  final int totalItems;
  final int missedCount;
  final VoidCallback onReviewMissed;
  final VoidCallback onRetake;
  final VoidCallback onBackToFolder;

  List<Widget> _actions() {
    if (missedCount == 0) {
      return [
        DesignButton(
          label: 'Retake test',
          variant: ButtonVariant.primary,
          onPressed: onRetake,
        ),
        DesignButton(label: 'Back to folder', onPressed: onBackToFolder),
      ];
    }

    return [
      DesignButton(
        label: 'Review the $missedCount missed',
        variant: ButtonVariant.primary,
        onPressed: onReviewMissed,
      ),
      DesignButton(label: 'Retake test', onPressed: onRetake),
    ];
  }

  Widget _detail(DesignColors colors) {
    final detailWidth = widthOfCharacters(
      _detailMeasureCharacters,
      textSize: TextSizes.medium,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: detailWidth),
      child: BalancedText(
        TextSpan(
          text:
              'The $missedCount you missed come back tomorrow. '
              'The rest are scheduled further out.',
        ),
        textAlign: TextAlign.center,
        style: textStyleForSize(TextSizes.medium)
            .copyWith(color: colors.inkSecondary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return SizedBox(
      width: double.infinity,
      child: TestCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: Spacing.step3,
          children: [
            const SectionLabel('Test complete'),
            Text(
              '$correctCount / $totalItems',
              style:
                  textStyleForSize(
                    TextSizes.tripleExtraLarge,
                    addedLetterSpacingInEm: _scoreLetterSpacingInEm,
                  ).copyWith(
                    fontWeight: FontWeight.w600,
                    height: _scoreLineHeight,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
            ),
            _detail(colors),
            Padding(
              padding: const EdgeInsets.only(top: Spacing.step3),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: Spacing.step2,
                runSpacing: Spacing.step2,
                children: _actions(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
