import 'package:flutter/painting.dart';

import 'design_metrics.dart';

const String _opticalSizeAxis = 'opsz';

final Map<double, double> _appleTrackingBySize = {
  TextSizes.extraSmall: 0,
  TextSizes.small: -0.15,
  TextSizes.medium: -0.31,
  TextSizes.large: -0.45,
  TextSizes.extraLarge: 0.07,
  TextSizes.doubleExtraLarge: 0.41,
  TextSizes.tripleExtraLarge: 0.35,
};

TextStyle textStyleForSize(
  double textSize, {
  double addedLetterSpacingInEm = 0,
}) {
  final appleTracking = _appleTrackingBySize[textSize];

  if (appleTracking == null) {
    throw ArgumentError.value(textSize, 'textSize', 'is not a design size');
  }

  final addedLetterSpacing = addedLetterSpacingInEm * textSize;

  return TextStyle(
    fontSize: textSize,
    letterSpacing: appleTracking + addedLetterSpacing,
    fontVariations: [FontVariation(_opticalSizeAxis, textSize)],
  );
}
