import 'package:flutter/material.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';

const double _faceMinimumHeight = 232;
const double _promptLineHeight = 1.35;

enum FaceSide { prompt, answer }

TextStyle faceTextStyle(FaceSide side, DesignColors colors) {
  final (weight, ink) = switch (side) {
    FaceSide.prompt => (FontWeight.w500, colors.ink),
    FaceSide.answer => (FontWeight.w400, colors.inkSecondary),
  };

  return textStyleForSize(TextSizes.extraLarge)
      .copyWith(color: ink, fontWeight: weight, height: _promptLineHeight);
}

class FlashcardFaceBox extends StatelessWidget {
  const FlashcardFaceBox({required this.side, required this.child, super.key});

  final FaceSide side;
  final Widget child;

  BoxDecoration? _decorationOf(DesignColors colors) {
    return switch (side) {
      FaceSide.prompt => null,
      FaceSide.answer => BoxDecoration(
        color: colors.surfaceSecondary,
        border: Border(top: BorderSide(color: colors.line)),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: _faceMinimumHeight),
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.step7,
        horizontal: Spacing.step6,
      ),
      decoration: _decorationOf(DesignColors.of(context)),
      child: Center(heightFactor: 1, child: child),
    );
  }
}
