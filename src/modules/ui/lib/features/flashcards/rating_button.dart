import 'package:flutter/material.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_shadows.dart';
import '../../shared/design/design_typography.dart';
import '../../shared/design/focus_outline.dart';
import '../../shared/design/pressable.dart';
import '../../shared/design/shortcut_chip.dart';
import '../../shared/design/surface_box.dart';
import 'flashcard_models.dart';

const EdgeInsets _ratingPadding = EdgeInsets.fromLTRB(
  Spacing.step4,
  0,
  Spacing.step3,
  0,
);

ShortcutChipTone _accentOf(FlashcardRating rating) {
  return switch (rating) {
    FlashcardRating.again => ShortcutChipTone.again,
    FlashcardRating.hard => ShortcutChipTone.hard,
    FlashcardRating.good || FlashcardRating.easy => ShortcutChipTone.good,
  };
}

SurfaceLook _ratingLookOf(InteractionState state, BuildContext context) {
  final colors = DesignColors.of(context);
  final shadows = DesignShadows.of(context);
  final isPointedAt = state.isHovered || state.isPressed;
  final fill = switch (state) {
    InteractionState(isPressed: true) => colors.surfaceTertiary,
    InteractionState(isHovered: true) => colors.surfaceSecondary,
    _ => colors.surface,
  };
  final edge = isPointedAt ? colors.lineHover : colors.lineStrong;

  return SurfaceLook(
    fill: fill,
    border: BorderSide(color: edge),
    shadows: shadows.raised,
    edgeHighlight: shadows.edgeHighlight,
  );
}

class RatingButton extends StatelessWidget {
  const RatingButton({
    required this.rating,
    required this.intervalText,
    required this.onPressed,
    super.key,
  });

  final FlashcardRating rating;
  final String intervalText;
  final VoidCallback onPressed;

  Widget _gridRowFor(Widget text) {
    return Expanded(
      child: Align(alignment: Alignment.centerLeft, child: text),
    );
  }

  Widget _buildFace(BuildContext context, InteractionState state) {
    final colors = DesignColors.of(context);
    final labelStyle = textStyleForSize(TextSizes.small).copyWith(
      color: colors.ink,
      fontWeight: FontWeight.w600,
      height: baseLineHeight,
    );
    final intervalStyle = textStyleForSize(TextSizes.extraSmall).copyWith(
      color: colors.inkTertiary,
      height: baseLineHeight,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return FocusOutline(
      state: state,
      borderRadius: Radii.medium,
      child: SizedBox(
        height: ControlHeights.extraLarge,
        child: SurfaceBox(
          look: _ratingLookOf(state, context),
          borderRadius: Radii.medium,
          padding: _ratingPadding,
          child: Row(
            spacing: Spacing.step3,
            children: [
              ShortcutChip(label: '${rating.score}', tone: _accentOf(rating)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _gridRowFor(Text(rating.label, style: labelStyle)),
                    _gridRowFor(Text(intervalText, style: intervalStyle)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(onPressed: onPressed, builder: _buildFace);
  }
}
