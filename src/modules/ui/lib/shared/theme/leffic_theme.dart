import 'package:flutter/material.dart';

import '../design/design_colors.dart';
import '../design/design_metrics.dart';
import '../design/design_typography.dart';

ThemeData lefficTheme(Brightness brightness) {
  final colors = DesignColors.forBrightness(brightness);

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: colors.brand,
    onPrimary: colors.onBrand,
    secondary: colors.brand,
    onSecondary: colors.onBrand,
    error: colors.danger,
    onError: colors.onBrand,
    surface: colors.surface,
    onSurface: colors.ink,
    onSurfaceVariant: colors.inkSecondary,
    outline: colors.lineStrong,
    outlineVariant: colors.line,
  );

  final baseText = textStyleForSize(TextSizes.medium).copyWith(
    color: colors.ink,
    fontWeight: FontWeight.w400,
    height: baseLineHeight,
    leadingDistribution: TextLeadingDistribution.even,
  );

  return ThemeData(
    brightness: brightness,
    colorScheme: colorScheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    scaffoldBackgroundColor: colors.surfaceSecondary,
    canvasColor: colors.surfaceSecondary,
    textTheme: TextTheme(bodyMedium: baseText),
  );
}
