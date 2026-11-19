import 'package:flutter/widgets.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_shadows.dart';
import '../../shared/design/panel_look.dart';
import '../../shared/design/surface_box.dart';

class FolderPanel extends StatelessWidget {
  const FolderPanel({required this.padding, required this.child, super.key});

  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final look = raisedPanelLookOf(
      colors: DesignColors.of(context),
      shadows: DesignShadows.of(context),
    );

    return SurfaceBox(
      look: look,
      borderRadius: Radii.large,
      padding: padding,
      child: child,
    );
  }
}
