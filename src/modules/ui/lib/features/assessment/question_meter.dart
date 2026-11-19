import 'package:flutter/material.dart';

import '../../shared/design/meter.dart';
import '../../shared/progress/study_progress.dart';

class QuestionMeter extends StatelessWidget {
  const QuestionMeter({
    required this.position,
    required this.totalItems,
    super.key,
  });

  final int position;
  final int totalItems;

  @override
  Widget build(BuildContext context) {
    final remaining = countRemaining(done: position, total: totalItems);
    final share = computeCompletedShare(done: position, total: totalItems);

    return MeterBlock(
      startLabel: 'Question $position of $totalItems',
      endLabel: '$remaining to go',
      fraction: share,
    );
  }
}
