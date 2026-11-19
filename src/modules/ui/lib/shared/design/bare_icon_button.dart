import 'package:flutter/material.dart';

import 'design_colors.dart';
import 'design_metrics.dart';
import 'focus_outline.dart';
import 'icons/design_icon.dart';
import 'icons/design_icons.dart';
import 'pressable.dart';
import 'surface_box.dart';

const Color _transparent = Color(0x00000000);

class BareIconButton extends StatelessWidget {
  const BareIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.side,
    required this.hoverFill,
    required this.hoverInk,
    required this.onPressed,
    super.key,
  });

  final DesignIcons icon;
  final String semanticLabel;
  final double side;
  final Color hoverFill;
  final Color hoverInk;
  final VoidCallback onPressed;

  Widget _buildFace(BuildContext context, InteractionState state) {
    final restingInk = DesignColors.of(context).inkTertiary;
    final look = SurfaceLook(
      fill: state.isHovered ? hoverFill : _transparent,
      border: BorderSide.none,
      shadows: const [],
      edgeHighlight: _transparent,
    );

    return FocusOutline(
      state: state,
      borderRadius: Radii.small,
      child: SizedBox.square(
        dimension: side,
        child: SurfaceBox(
          look: look,
          borderRadius: Radii.small,
          child: Center(
            child: DesignIcon(
              icon,
              size: IconSizes.small,
              color: state.isHovered ? hoverInk : restingInk,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      builder: _buildFace,
    );
  }
}
