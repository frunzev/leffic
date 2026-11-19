import 'package:flutter/material.dart';

import '../../shared/design/card_look.dart';
import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_shadows.dart';
import '../../shared/design/surface_box.dart';

const double _borderWidth = 1;

class FlashcardCard extends StatelessWidget {
  const FlashcardCard({required this.faces, required this.menu, super.key});

  final List<Widget> faces;
  final Widget menu;

  @override
  Widget build(BuildContext context) {
    final look = cardLookOf(
      colors: DesignColors.of(context),
      shadows: DesignShadows.of(context),
    );

    return SurfaceBox(
      look: look,
      borderRadius: Radii.large,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.large - _borderWidth),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: faces,
              ),
            ),
            Positioned(top: Spacing.step3, right: Spacing.step3, child: menu),
          ],
        ),
      ),
    );
  }
}
