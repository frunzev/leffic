import 'package:flutter/material.dart';

class DesignColors {
  const DesignColors({
    required this.brand,
    required this.brandStrong,
    required this.brandSurface,
    required this.brandSurfaceStrong,
    required this.onBrand,
    required this.brandMark,
    required this.onBrandChip,
    required this.ink,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.surface,
    required this.surfaceSecondary,
    required this.surfaceTertiary,
    required this.hover,
    required this.line,
    required this.lineStrong,
    required this.lineHover,
    required this.again,
    required this.hard,
    required this.good,
    required this.danger,
    required this.dangerSurface,
    required this.success,
    required this.paper,
    required this.paperInk,
    required this.paperInkSecondary,
    required this.paperLine,
    required this.scrim,
  });

  static DesignColors of(BuildContext context) {
    return forBrightness(Theme.of(context).brightness);
  }

  static DesignColors forBrightness(Brightness brightness) {
    return switch (brightness) {
      Brightness.light => _lightColors,
      Brightness.dark => _darkColors,
    };
  }

  final Color brand;
  final Color brandStrong;
  final Color brandSurface;
  final Color brandSurfaceStrong;
  final Color onBrand;
  final Color brandMark;
  final Color onBrandChip;
  final Color ink;
  final Color inkSecondary;
  final Color inkTertiary;
  final Color surface;
  final Color surfaceSecondary;
  final Color surfaceTertiary;
  final Color hover;
  final Color line;
  final Color lineStrong;
  final Color lineHover;
  final Color again;
  final Color hard;
  final Color good;
  final Color danger;
  final Color dangerSurface;
  final Color success;
  final Color paper;
  final Color paperInk;
  final Color paperInkSecondary;
  final Color paperLine;
  final Color scrim;
}

const DesignColors _lightColors = DesignColors(
  brand: Color(0xFF1A6FD4),
  brandStrong: Color(0xFF14559F),
  brandSurface: Color(0xFFEDF3FB),
  brandSurfaceStrong: Color(0xFFD9E6F8),
  onBrand: Color(0xFFFFFFFF),
  brandMark: Color(0xFFFFFFFF),
  onBrandChip: Color.fromRGBO(255, 255, 255, 0.18),
  ink: Color(0xFF141C2B),
  inkSecondary: Color(0xFF465063),
  inkTertiary: Color(0xFF636D80),
  surface: Color(0xFFFFFFFF),
  surfaceSecondary: Color(0xFFF4F7FB),
  surfaceTertiary: Color(0xFFE9EEF5),
  hover: Color(0xFFEFF3F8),
  line: Color(0xFFE1E7EF),
  lineStrong: Color(0xFFCFD8E4),
  lineHover: Color(0xFFB1BDCD),
  again: Color(0xFFB3261E),
  hard: Color(0xFFA05A00),
  good: Color(0xFF1C7C54),
  danger: Color(0xFFB3261E),
  dangerSurface: Color(0xFFFDF0EF),
  success: Color(0xFF1C7C54),
  paper: Color(0xFFFFFFFF),
  paperInk: Color(0xFF141C2B),
  paperInkSecondary: Color(0xFF465063),
  paperLine: Color(0xFFE1E7EF),
  scrim: Color.fromRGBO(20, 28, 43, 0.34),
);

const DesignColors _darkColors = DesignColors(
  brand: Color(0xFF4D94EE),
  brandStrong: Color(0xFF7CB2F5),
  brandSurface: Color(0xFF15263A),
  brandSurfaceStrong: Color(0xFF1C334E),
  onBrand: Color(0xFF0D1117),
  brandMark: Color(0xFFFFFFFF),
  onBrandChip: Color.fromRGBO(13, 17, 23, 0.16),
  ink: Color(0xFFE8EEF8),
  inkSecondary: Color(0xFFAFBDD3),
  inkTertiary: Color(0xFF8193AE),
  surface: Color(0xFF132035),
  surfaceSecondary: Color(0xFF0D1627),
  surfaceTertiary: Color(0xFF1B2B45),
  hover: Color(0xFF182740),
  line: Color(0xFF22324D),
  lineStrong: Color(0xFF2C3F5F),
  lineHover: Color(0xFF42587C),
  again: Color(0xFFFF8A7F),
  hard: Color(0xFFF2B55E),
  good: Color(0xFF5ED3A0),
  danger: Color(0xFFFF8A7F),
  dangerSurface: Color(0xFF331A26),
  success: Color(0xFF5ED3A0),
  paper: Color(0xFFE8EDF4),
  paperInk: Color(0xFF141C2B),
  paperInkSecondary: Color(0xFF465063),
  paperLine: Color(0xFFC8D1DE),
  scrim: Color.fromRGBO(3, 7, 16, 0.66),
);
