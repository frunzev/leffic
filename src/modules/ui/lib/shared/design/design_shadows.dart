import 'package:flutter/material.dart';

import 'design_colors.dart';

class CssBoxShadow extends BoxShadow {
  const CssBoxShadow({
    required super.color,
    required this.cssBlur,
    super.offset,
    super.spreadRadius,
  }) : super(blurRadius: cssBlur);

  final double cssBlur;

  @override
  double get blurSigma => cssBlur / 2;
}

class DesignShadows {
  const DesignShadows({
    required this.edgeHighlight,
    required this.raised,
    required this.level2,
    required this.level3,
    required this.brand,
    required this.focusRing,
  });

  static DesignShadows of(BuildContext context) {
    return forBrightness(Theme.of(context).brightness);
  }

  static DesignShadows forBrightness(Brightness brightness) {
    return switch (brightness) {
      Brightness.light => _lightShadows,
      Brightness.dark => _darkShadows,
    };
  }

  final Color edgeHighlight;
  final List<BoxShadow> raised;
  final List<BoxShadow> level2;
  final List<BoxShadow> level3;
  final List<BoxShadow> brand;
  final List<BoxShadow> focusRing;
}

const Color _lightShade = Color.fromRGBO(20, 28, 43, 0.05);
const Color _darkShade = Color.fromRGBO(2, 6, 14, 0.4);
const double _focusRingWidth = 3;

List<BoxShadow> _focusRingOf(Brightness brightness) {
  final colors = DesignColors.forBrightness(brightness);

  return [
    CssBoxShadow(
      color: colors.brandSurfaceStrong,
      cssBlur: 0,
      spreadRadius: _focusRingWidth,
    ),
  ];
}

final DesignShadows _lightShadows = DesignShadows(
  edgeHighlight: const Color(0x00000000),
  raised: const [
    CssBoxShadow(color: _lightShade, offset: Offset(0, 1), cssBlur: 1),
  ],
  level2: const [
    CssBoxShadow(
      color: Color.fromRGBO(20, 28, 43, 0.16),
      offset: Offset(0, 16),
      cssBlur: 40,
      spreadRadius: -16,
    ),
    CssBoxShadow(color: _lightShade, offset: Offset(0, 1), cssBlur: 2),
  ],
  level3: const [
    CssBoxShadow(
      color: Color.fromRGBO(20, 28, 43, 0.3),
      offset: Offset(0, 28),
      cssBlur: 56,
      spreadRadius: -16,
    ),
  ],
  brand: const [
    CssBoxShadow(
      color: Color.fromRGBO(26, 111, 212, 0.5),
      offset: Offset(0, 8),
      cssBlur: 20,
      spreadRadius: -10,
    ),
    CssBoxShadow(
      color: Color.fromRGBO(26, 111, 212, 0.24),
      offset: Offset(0, 1),
      cssBlur: 2,
    ),
  ],
  focusRing: _focusRingOf(Brightness.light),
);

final DesignShadows _darkShadows = DesignShadows(
  edgeHighlight: const Color.fromRGBO(174, 205, 245, 0.07),
  raised: const [
    CssBoxShadow(
      color: Color.fromRGBO(2, 6, 14, 0.3),
      offset: Offset(0, 1),
      cssBlur: 1,
    ),
  ],
  level2: const [
    CssBoxShadow(
      color: Color.fromRGBO(2, 6, 14, 0.8),
      offset: Offset(0, 16),
      cssBlur: 40,
      spreadRadius: -16,
    ),
    CssBoxShadow(color: _darkShade, offset: Offset(0, 1), cssBlur: 2),
  ],
  level3: const [
    CssBoxShadow(
      color: Color.fromRGBO(2, 6, 14, 0.9),
      offset: Offset(0, 28),
      cssBlur: 56,
      spreadRadius: -16,
    ),
  ],
  brand: const [
    CssBoxShadow(
      color: Color.fromRGBO(77, 148, 238, 0.55),
      offset: Offset(0, 8),
      cssBlur: 20,
      spreadRadius: -10,
    ),
    CssBoxShadow(color: _darkShade, offset: Offset(0, 1), cssBlur: 2),
  ],
  focusRing: _focusRingOf(Brightness.dark),
);
