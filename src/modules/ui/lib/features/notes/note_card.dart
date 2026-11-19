import 'package:flutter/material.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_shadows.dart';
import '../../shared/design/panel_look.dart';
import '../../shared/design/surface_box.dart';

const double _cardWidth = 760;

class NoteCard extends StatelessWidget {
  const NoteCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);
    final shadows = DesignShadows.of(context);

    return Padding(
      padding: const EdgeInsets.all(Spacing.step4),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.step5),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _cardWidth),
            child: SizedBox(
              width: double.infinity,
              child: SurfaceBox(
                look: raisedPanelLookOf(colors: colors, shadows: shadows),
                borderRadius: Radii.large,
                padding: const EdgeInsets.all(Spacing.step7),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
