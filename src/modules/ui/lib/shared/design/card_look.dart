import 'package:flutter/material.dart';

import 'design_colors.dart';
import 'design_shadows.dart';
import 'surface_box.dart';

SurfaceLook cardLookOf({
  required DesignColors colors,
  required DesignShadows shadows,
}) {
  return SurfaceLook(
    fill: colors.surface,
    border: BorderSide(color: colors.line),
    shadows: shadows.level2,
    edgeHighlight: shadows.edgeHighlight,
  );
}
