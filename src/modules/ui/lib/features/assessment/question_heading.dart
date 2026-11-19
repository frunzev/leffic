import 'package:flutter/material.dart';

import '../../shared/design/balanced_text.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';

const double _questionLineHeight = 1.4;
const double _menuReserve = ControlHeights.regular + Spacing.step3;

class QuestionHeading extends StatelessWidget {
  const QuestionHeading(this.question, {super.key});

  final String question;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: _menuReserve),
      child: BalancedText(
        TextSpan(text: question),
        style: textStyleForSize(TextSizes.large)
            .copyWith(fontWeight: FontWeight.w600, height: _questionLineHeight),
      ),
    );
  }
}
