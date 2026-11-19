import 'package:flutter/material.dart';

import '../../shared/design/card_look.dart';
import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_shadows.dart';
import '../../shared/design/surface_box.dart';

const EdgeInsets _cardPadding = EdgeInsets.symmetric(
  vertical: Spacing.step6,
  horizontal: Spacing.step5,
);

class TestCard extends StatelessWidget {
  const TestCard({required this.child, this.menu, super.key});

  final Widget child;
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    final cardMenu = menu;
    final look = cardLookOf(
      colors: DesignColors.of(context),
      shadows: DesignShadows.of(context),
    );

    return SurfaceBox(
      look: look,
      borderRadius: Radii.large,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          SingleChildScrollView(padding: _cardPadding, child: child),
          if (cardMenu != null)
            Positioned(
              top: Spacing.step3,
              right: Spacing.step3,
              child: cardMenu,
            ),
        ],
      ),
    );
  }
}
