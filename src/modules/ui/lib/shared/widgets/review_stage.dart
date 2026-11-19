import 'package:flutter/material.dart';

import '../design/design_metrics.dart';

const BoxConstraints _innerLimits = BoxConstraints(
  maxWidth: 720,
  maxHeight: 760,
);

class ReviewStage extends StatelessWidget {
  const ReviewStage({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.step4),
      child: Center(
        child: ConstrainedBox(
          constraints: _innerLimits,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.step4),
            child: child,
          ),
        ),
      ),
    );
  }
}
