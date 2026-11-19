import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_metrics.dart';
import 'package:leffic/shared/design/design_typography.dart';

import '../../support/property.dart';
import '../../support/system_fonts.dart';

const double _tolerance = 1e-9;
const double _chromeWidthTolerance = 0.5;
const String _opticalSizeAxis = 'opsz';
const String _systemFontFamily = '.AppleSystemUIFont';
const String _sample = 'The quick brown fox jumps over the lazy dog 0123456789';

final Map<double, double> _appleTrackingBySize = {
  12: 0,
  14: -0.15,
  16: -0.31,
  20: -0.45,
  24: 0.07,
  32: 0.41,
  48: 0.35,
};

const List<(double, FontWeight, double)> _chromeSampleWidths = [
  (12, FontWeight.w400, 328.375),
  (12, FontWeight.w500, 335.125),
  (12, FontWeight.w600, 341.813),
  (14, FontWeight.w400, 374.984),
  (14, FontWeight.w500, 382.859),
  (14, FontWeight.w600, 390.672),
  (16, FontWeight.w400, 420.953),
  (16, FontWeight.w500, 429.953),
  (16, FontWeight.w600, 438.875),
  (20, FontWeight.w400, 508.703),
  (20, FontWeight.w500, 520.391),
  (20, FontWeight.w600, 531.984),
  (24, FontWeight.w400, 600.938),
  (24, FontWeight.w500, 616.203),
  (24, FontWeight.w600, 631.469),
  (32, FontWeight.w400, 800.500),
  (32, FontWeight.w500, 821.500),
  (32, FontWeight.w600, 842.328),
  (48, FontWeight.w400, 1186.828),
  (48, FontWeight.w500, 1218.328),
  (48, FontWeight.w600, 1249.578),
];

double _designSizeOf(Random random) {
  return oneOf(random, _appleTrackingBySize.keys.toList());
}

double _sampleWidthOf(TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: _sample, style: style),
    textDirection: TextDirection.ltr,
  );

  painter.layout();
  final sampleWidth = painter.width;
  painter.dispose();

  return sampleWidth;
}

void main() {
  test('textStyleForSize property sets the size and its optical size', () {
    forAll(_designSizeOf, (fontSize) {
      final style = textStyleForSize(fontSize);

      expect(style.fontSize, fontSize);
      expect(style.fontVariations, [FontVariation(_opticalSizeAxis, fontSize)]);
    });
  });

  test('textStyleForSize property applies the Apple tracking of the size', () {
    for (final MapEntry(key: fontSize, value: tracking)
        in _appleTrackingBySize.entries) {
      expect(textStyleForSize(fontSize).letterSpacing, tracking);
    }
  });

  test('textStyleForSize property covers every design text size', () {
    const designSizes = [
      TextSizes.extraSmall,
      TextSizes.small,
      TextSizes.medium,
      TextSizes.large,
      TextSizes.extraLarge,
      TextSizes.doubleExtraLarge,
      TextSizes.tripleExtraLarge,
    ];

    for (final fontSize in designSizes) {
      expect(textStyleForSize(fontSize).fontSize, fontSize);
    }
  });

  test('textStyleForSize property adds CSS letter spacing in em', () {
    forAll(
      (random) =>
          (_designSizeOf(random), integerBetween(random, -30, 30) / 1000),
      (example) {
        final (fontSize, letterSpacingInEm) = example;
        final tracking = textStyleForSize(fontSize).letterSpacing ?? 0;
        final spaced = textStyleForSize(
          fontSize,
          addedLetterSpacingInEm: letterSpacingInEm,
        );

        expect(
          spaced.letterSpacing,
          closeTo(tracking + letterSpacingInEm * fontSize, _tolerance),
        );
      },
    );
  });

  test('textStyleForSize property rejects a size outside the design scale', () {
    forAll((random) => integerBetween(random, 1, 4000) / 37, (fontSize) {
      if (_appleTrackingBySize.containsKey(fontSize)) {
        return;
      }

      expect(() => textStyleForSize(fontSize), throwsArgumentError);
    });
  });

  test('textStyleForSize property sets SF Pro as wide as Chrome', () async {
    await loadSystemFonts();

    for (final (fontSize, fontWeight, chromeWidth) in _chromeSampleWidths) {
      final sizedStyle = textStyleForSize(fontSize);
      final style = sizedStyle.copyWith(
        fontFamily: _systemFontFamily,
        fontWeight: fontWeight,
      );

      expect(
        _sampleWidthOf(style),
        closeTo(chromeWidth, _chromeWidthTolerance),
        reason: 'size $fontSize weight ${fontWeight.value}',
      );
    }
  });
}
