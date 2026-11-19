import 'package:flutter/material.dart';

import 'design_colors.dart';
import 'design_shadows.dart';
import 'surface_box.dart';

SurfaceLook raisedPanelLookOf({
  required DesignColors colors,
  required DesignShadows shadows,
}) {
  return SurfaceLook(
    fill: colors.surface,
    border: BorderSide(color: colors.line),
    shadows: shadows.raised,
    edgeHighlight: shadows.edgeHighlight,
  );
}

SurfaceLook floatingPanelLookOf({
  required DesignColors colors,
  required DesignShadows shadows,
}) {
  return SurfaceLook(
    fill: colors.surface,
    border: BorderSide(color: colors.line),
    shadows: shadows.level3,
    edgeHighlight: shadows.edgeHighlight,
  );
}
