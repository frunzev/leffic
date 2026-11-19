import 'package:flutter/material.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';
import '../../shared/design/focus_outline.dart';
import '../../shared/design/pressable.dart';
import '../../shared/design/surface_box.dart';

const double _optionMinimumHeight = 52;
const double _letterSide = 24;
const Color _transparent = Color(0x00000000);
const EdgeInsets _optionPadding = EdgeInsets.symmetric(
  vertical: Spacing.step2,
  horizontal: Spacing.step4,
);

@immutable
class AnswerOptionLook {
  const AnswerOptionLook({
    required this.surface,
    required this.keyFill,
    required this.keyInk,
  });

  final SurfaceLook surface;
  final Color keyFill;
  final Color keyInk;
}

AnswerOptionLook _flatOptionLook({
  required Color border,
  required Color fill,
  required Color keyFill,
  required Color keyInk,
}) {
  final surface = SurfaceLook(
    fill: fill,
    border: BorderSide(color: border),
    shadows: const [],
    edgeHighlight: _transparent,
  );

  return AnswerOptionLook(surface: surface, keyFill: keyFill, keyInk: keyInk);
}

AnswerOptionLook answerOptionLookOf({
  required InteractionState state,
  required bool isChosen,
  required DesignColors colors,
}) {
  if (isChosen) {
    return _flatOptionLook(
      border: colors.brand,
      fill: colors.brandSurface,
      keyFill: colors.brand,
      keyInk: colors.onBrand,
    );
  }

  if (state.isHovered) {
    return _flatOptionLook(
      border: colors.lineHover,
      fill: colors.surfaceTertiary,
      keyFill: colors.surface,
      keyInk: colors.inkSecondary,
    );
  }

  return _flatOptionLook(
    border: colors.line,
    fill: colors.surfaceSecondary,
    keyFill: colors.surfaceTertiary,
    keyInk: colors.inkSecondary,
  );
}

class OptionLetterBadge extends StatelessWidget {
  const OptionLetterBadge({
    required this.letter,
    required this.fill,
    required this.ink,
    super.key,
  });

  final String letter;
  final Color fill;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _letterSide,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(Radii.small),
        ),
        child: Center(
          child: Text(
            letter,
            style: textStyleForSize(TextSizes.extraSmall)
                .copyWith(color: ink, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class AnswerOptionButton extends StatelessWidget {
  const AnswerOptionButton({
    required this.letter,
    required this.text,
    required this.isChosen,
    required this.onPressed,
    super.key,
  });

  final String letter;
  final String text;
  final bool isChosen;
  final VoidCallback onPressed;

  Widget _buildFace(BuildContext context, InteractionState state) {
    final colors = DesignColors.of(context);
    final look = answerOptionLookOf(
      state: state,
      isChosen: isChosen,
      colors: colors,
    );

    return FocusOutline(
      state: state,
      borderRadius: Radii.medium,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _optionMinimumHeight),
        child: SurfaceBox(
          look: look.surface,
          borderRadius: Radii.medium,
          padding: _optionPadding,
          child: Row(
            spacing: Spacing.step3,
            children: [
              OptionLetterBadge(
                letter: letter,
                fill: look.keyFill,
                ink: look.keyInk,
              ),
              Expanded(
                child: Text(
                  text,
                  style: textStyleForSize(TextSizes.medium)
                      .copyWith(color: colors.ink),
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
    return Semantics(
      selected: isChosen,
      child: Pressable(onPressed: onPressed, builder: _buildFace),
    );
  }
}
