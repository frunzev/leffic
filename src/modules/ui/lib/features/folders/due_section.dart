import 'package:flutter/widgets.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';
import '../../shared/design/icons/design_icon.dart';
import '../../shared/design/icons/design_icons.dart';
import '../../shared/design/meter.dart';
import '../../shared/design/section_label.dart';
import 'due_models.dart';
import 'folder_panel.dart';
import 'review_menu.dart';

const String _dueHeading = 'Due today';
const List<FontFeature> _tabularFigures = [FontFeature.tabularFigures()];

class DueSection extends StatelessWidget {
  const DueSection({
    required this.due,
    required this.onReviewFlashcards,
    required this.onTakeTest,
    super.key,
  });

  final DueSummary due;
  final VoidCallback onReviewFlashcards;
  final VoidCallback onTakeTest;

  @override
  Widget build(BuildContext context) {
    final progressStyle = textStyleForSize(TextSizes.small).copyWith(
      color: DesignColors.of(context).inkTertiary,
      fontFeatures: _tabularFigures,
    );
    final breakdown = Wrap(
      spacing: Spacing.step5,
      runSpacing: Spacing.step2,
      children: [
        DueItem(
          icon: DesignIcons.flashcards,
          count: due.flashcards.due,
          label: 'flashcards',
        ),
        DueItem(
          icon: DesignIcons.test,
          count: due.testItems.due,
          label: 'test items',
        ),
        DueItem(icon: DesignIcons.note, count: due.notes.due, label: 'notes'),
      ],
    );

    return FolderPanel(
      padding: const EdgeInsets.all(Spacing.step5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: Spacing.step4,
            children: [
              const SectionLabel(_dueHeading),
              Text(
                '${due.doneCount} of ${due.totalCount} done',
                style: progressStyle,
              ),
            ],
          ),
          const SizedBox(height: Spacing.step2),
          Meter(fraction: due.completedShare),
          const SizedBox(height: Spacing.step4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: Spacing.step4,
            children: [
              Flexible(child: breakdown),
              ReviewMenu(
                due: due,
                onReviewFlashcards: onReviewFlashcards,
                onTakeTest: onTakeTest,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DueItem extends StatelessWidget {
  const DueItem({
    required this.icon,
    required this.count,
    required this.label,
    super.key,
  });

  final DesignIcons icon;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);
    final countColor = count == 0 ? colors.good : colors.ink;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Spacing.step2,
      children: [
        DesignIcon(icon, size: IconSizes.small, color: colors.inkTertiary),
        Text(
          '$count',
          style: textStyleForSize(TextSizes.large).copyWith(
            color: countColor,
            fontWeight: FontWeight.w600,
            fontFeatures: _tabularFigures,
          ),
        ),
        Text(
          label,
          style: textStyleForSize(TextSizes.small)
              .copyWith(color: colors.inkSecondary),
        ),
      ],
    );
  }
}
