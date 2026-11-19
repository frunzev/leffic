import 'package:flutter/material.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_shadows.dart';
import '../../shared/design/surface_box.dart';

const double _pageWidth = 680;
const double _paperBorderWidth = 1;

class FileViewer extends StatelessWidget {
  const FileViewer({required this.document, super.key});

  final Widget document;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);
    final shadows = DesignShadows.of(context);

    return ColoredBox(
      color: colors.surfaceTertiary,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Spacing.step5,
          horizontal: Spacing.step4,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _pageWidth),
            child: SizedBox.expand(
              child: SurfaceBox(
                look: SurfaceLook(
                  fill: colors.paper,
                  border: BorderSide(color: colors.paperLine),
                  shadows: shadows.level2,
                  edgeHighlight: shadows.edgeHighlight,
                ),
                borderRadius: Radii.small,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Radii.small - _paperBorderWidth,
                  ),
                  child: document,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
