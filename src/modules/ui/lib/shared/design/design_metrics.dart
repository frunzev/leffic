import 'package:flutter/animation.dart';

const double baseLineHeight = 1.55;
const double _zeroAdvancePerFontSize = 0.6298828125;

double widthOfCharacters(int characterCount, {required double textSize}) {
  return characterCount * textSize * _zeroAdvancePerFontSize;
}

abstract final class Spacing {
  static const double step1 = 4;
  static const double step2 = 8;
  static const double step3 = 12;
  static const double step4 = 16;
  static const double step5 = 24;
  static const double step6 = 32;
  static const double step7 = 48;
  static const double step8 = 64;
}

abstract final class TextSizes {
  static const double extraSmall = 12;
  static const double small = 14;
  static const double medium = 16;
  static const double large = 20;
  static const double extraLarge = 24;
  static const double doubleExtraLarge = 32;
  static const double tripleExtraLarge = 48;
}

abstract final class Radii {
  static const double extraSmall = 6;
  static const double small = 8;
  static const double medium = 10;
  static const double large = 14;
  static const double pill = 999;
}

abstract final class ControlHeights {
  static const double small = 34;
  static const double regular = 40;
  static const double large = 44;
  static const double extraLarge = 56;
}

abstract final class IconSizes {
  static const double regular = 20;
  static const double small = 18;
}

abstract final class LayoutSizes {
  static const double meterHeight = 6;
  static const double railWidth = 72;
  static const double railBarHeight = 60;
}

abstract final class Motion {
  static const Duration duration = Duration(milliseconds: 140);
  static const Cubic curve = Cubic(0.2, 0, 0, 1);
}
