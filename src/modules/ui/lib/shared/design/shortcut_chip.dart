import 'package:flutter/material.dart';

import 'design_colors.dart';
import 'design_metrics.dart';
import 'design_typography.dart';

const double _keySide = 22;
const double _accentFillOpacity = 0.14;

enum ShortcutChipTone { plain, onBrand, again, hard, good }

(Color, Color) _accentColours(Color accent) {
  return (accent.withValues(alpha: _accentFillOpacity), accent);
}

class ShortcutChip extends StatelessWidget {
  const ShortcutChip({required this.label, required this.tone, super.key});

  final String label;
  final ShortcutChipTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);
    final (fill, ink) = switch (tone) {
      ShortcutChipTone.plain => (colors.surfaceTertiary, colors.inkSecondary),
      ShortcutChipTone.onBrand => (colors.onBrandChip, colors.onBrand),
      ShortcutChipTone.again => _accentColours(colors.again),
      ShortcutChipTone.hard => _accentColours(colors.hard),
      ShortcutChipTone.good => _accentColours(colors.good),
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: _keySide,
        minHeight: _keySide,
        maxHeight: _keySide,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(Radii.small),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.step2),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: textStyleForSize(TextSizes.extraSmall)
                  .copyWith(color: ink, fontWeight: FontWeight.w600, height: 1),
            ),
          ),
        ),
      ),
    );
  }
}
