import 'package:flutter/widgets.dart';

import '../../shared/design/button_look.dart';
import '../../shared/design/design_button.dart';
import '../../shared/design/design_dropdown.dart';
import '../../shared/design/icons/design_icons.dart';
import 'due_models.dart';
import 'unit_presentation.dart';

class ReviewMenu extends StatelessWidget {
  const ReviewMenu({
    required this.due,
    required this.onReviewFlashcards,
    required this.onTakeTest,
    super.key,
  });

  final DueSummary due;
  final VoidCallback onReviewFlashcards;
  final VoidCallback onTakeTest;

  List<DropdownEntry> _dueReviews() {
    final flashcardsDue = due.flashcards.due;
    final testItemsDue = due.testItems.due;

    return [
      if (flashcardsDue > 0)
        DropdownAction(
          icon: DesignIcons.flashcards,
          label: 'Flashcards',
          hint: '$flashcardsDue due',
          onSelected: onReviewFlashcards,
        ),
      if (testItemsDue > 0)
        DropdownAction(
          icon: DesignIcons.test,
          label: 'Test',
          hint: '$testItemsDue due',
          onSelected: onTakeTest,
        ),
    ];
  }

  Widget _buildButton(BuildContext context, OverlayPortalController menu) {
    final reviewableCount = due.reviewableCount;
    final canReview = reviewableCount > 0;

    return DesignButton(
      label: 'Review ${itemCountLabel(reviewableCount)}',
      icon: DesignIcons.study,
      variant: ButtonVariant.primary,
      onPressed: canReview ? menu.toggle : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DesignDropdown(
      placement: DropdownPlacement.belowEnd,
      entries: _dueReviews(),
      anchorBuilder: _buildButton,
    );
  }
}
