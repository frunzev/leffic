import 'package:flutter/material.dart';

import '../../shared/design/meter.dart';
import 'review_queue.dart';

class ReviewMeter extends StatelessWidget {
  const ReviewMeter({required this.queue, super.key});

  final ReviewQueue queue;

  @override
  Widget build(BuildContext context) {
    return MeterBlock(
      startLabel: 'Reviewed ${queue.reviewedCount} of ${queue.totalToReview}',
      endLabel: '${queue.leftCount} left',
      fraction: queue.completedShare,
    );
  }
}
