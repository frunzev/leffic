import 'package:flutter/material.dart';

import 'design_colors.dart';
import 'design_metrics.dart';
import 'design_shadows.dart';
import 'design_typography.dart';
import 'focus_outline.dart';
import 'icons/design_icon.dart';
import 'icons/design_icons.dart';
import 'panel_look.dart';
import 'pressable.dart';
import 'surface_box.dart';

const double _panelMinimumWidth = 208;
const double _itemIconOpacity = 0.7;
const Color _transparent = Color(0x00000000);

enum DropdownTone { plain, danger }

class DropdownPanel extends StatelessWidget {
  const DropdownPanel({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);
    final shadows = DesignShadows.of(context);
    final look = floatingPanelLookOf(colors: colors, shadows: shadows);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _panelMinimumWidth),
      child: IntrinsicWidth(
        child: SurfaceBox(
          look: look,
          borderRadius: Radii.medium,
          padding: const EdgeInsets.all(Spacing.step1),
          child: DefaultTextStyle.merge(
            style: textStyleForSize(TextSizes.small)
                .copyWith(color: colors.ink),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

class DropdownItem extends StatelessWidget {
  const DropdownItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.hint,
    this.tone = DropdownTone.plain,
    super.key,
  });

  final DesignIcons icon;
  final String label;
  final String? hint;
  final DropdownTone tone;
  final VoidCallback onPressed;

  Widget _buildFace(BuildContext context, InteractionState state) {
    final colors = DesignColors.of(context);
    final itemHint = hint;
    final (ink, hoverFill) = switch (tone) {
      DropdownTone.plain => (colors.ink, colors.hover),
      DropdownTone.danger => (colors.danger, colors.dangerSurface),
    };

    return FocusOutline(
      state: state,
      borderRadius: Radii.small,
      child: Container(
        height: ControlHeights.regular,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.step2),
        decoration: BoxDecoration(
          color: state.isHovered ? hoverFill : _transparent,
          borderRadius: BorderRadius.circular(Radii.small),
        ),
        child: DefaultTextStyle.merge(
          style: textStyleForSize(TextSizes.small).copyWith(color: ink),
          child: Row(
            spacing: Spacing.step3,
            children: [
              Opacity(
                opacity: _itemIconOpacity,
                child: DesignIcon(icon, size: IconSizes.small),
              ),
              Expanded(child: Text(label, maxLines: 1, softWrap: false)),
              if (itemHint != null)
                Text(
                  itemHint,
                  style: textStyleForSize(TextSizes.extraSmall).copyWith(
                    color: colors.inkTertiary,
                    fontFeatures: const [FontFeature.tabularFigures()],
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
