import 'package:flutter/material.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';
import 'flashcard_models.dart';
import 'interval_label.dart';
import 'rating_button.dart';

typedef IntervalsLoader = Future<RatingIntervals> Function();

class RatingButtons extends StatefulWidget {
  const RatingButtons({
    required this.loadIntervals,
    required this.onRate,
    super.key,
  });

  final IntervalsLoader loadIntervals;
  final ValueChanged<FlashcardRating> onRate;

  @override
  State<RatingButtons> createState() => _RatingButtonsState();
}

class _RatingButtonsState extends State<RatingButtons> {
  late final Future<RatingIntervals> _intervals = widget.loadIntervals();

  String _intervalText(
    AsyncSnapshot<RatingIntervals> snapshot,
    FlashcardRating rating,
  ) {
    final loadedIntervals = snapshot.data;

    if (loadedIntervals == null) {
      return '';
    }

    return intervalLabel(loadedIntervals.secondsFor(rating));
  }

  Widget _buildGrid(
    BuildContext context,
    AsyncSnapshot<RatingIntervals> snapshot,
  ) {
    final failureStyle = textStyleForSize(TextSizes.small)
        .copyWith(color: DesignColors.of(context).danger);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spacing.step2,
      children: [
        Row(
          spacing: Spacing.step2,
          children: [
            for (final rating in FlashcardRating.values)
              Expanded(
                child: RatingButton(
                  rating: rating,
                  intervalText: _intervalText(snapshot, rating),
                  onPressed: () => widget.onRate(rating),
                ),
              ),
          ],
        ),
        if (snapshot.hasError) Text('${snapshot.error}', style: failureStyle),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RatingIntervals>(
      future: _intervals,
      builder: _buildGrid,
    );
  }
}
