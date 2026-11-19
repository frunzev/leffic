import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_colors.dart';

import '../../support/property.dart';

typedef _TokenReader = Color Function(DesignColors colors);

class _TokenPair {
  const _TokenPair(this.read, this.light, this.dark);

  final _TokenReader read;
  final Color light;
  final Color dark;
}

final List<_TokenPair> _cssPairs = [
  _TokenPair(
    (colors) => colors.brand,
    const Color(0xFF1A6FD4),
    const Color(0xFF4D94EE),
  ),
  _TokenPair(
    (colors) => colors.brandStrong,
    const Color(0xFF14559F),
    const Color(0xFF7CB2F5),
  ),
  _TokenPair(
    (colors) => colors.brandSurface,
    const Color(0xFFEDF3FB),
    const Color(0xFF15263A),
  ),
  _TokenPair(
    (colors) => colors.brandSurfaceStrong,
    const Color(0xFFD9E6F8),
    const Color(0xFF1C334E),
  ),
  _TokenPair(
    (colors) => colors.onBrand,
    const Color(0xFFFFFFFF),
    const Color(0xFF0D1117),
  ),
  _TokenPair(
    (colors) => colors.brandMark,
    const Color(0xFFFFFFFF),
    const Color(0xFFFFFFFF),
  ),
  _TokenPair(
    (colors) => colors.onBrandChip,
    const Color.fromRGBO(255, 255, 255, 0.18),
    const Color.fromRGBO(13, 17, 23, 0.16),
  ),
  _TokenPair(
    (colors) => colors.ink,
    const Color(0xFF141C2B),
    const Color(0xFFE8EEF8),
  ),
  _TokenPair(
    (colors) => colors.inkSecondary,
    const Color(0xFF465063),
    const Color(0xFFAFBDD3),
  ),
  _TokenPair(
    (colors) => colors.inkTertiary,
    const Color(0xFF636D80),
    const Color(0xFF8193AE),
  ),
  _TokenPair(
    (colors) => colors.surface,
    const Color(0xFFFFFFFF),
    const Color(0xFF132035),
  ),
  _TokenPair(
    (colors) => colors.surfaceSecondary,
    const Color(0xFFF4F7FB),
    const Color(0xFF0D1627),
  ),
  _TokenPair(
    (colors) => colors.surfaceTertiary,
    const Color(0xFFE9EEF5),
    const Color(0xFF1B2B45),
  ),
  _TokenPair(
    (colors) => colors.hover,
    const Color(0xFFEFF3F8),
    const Color(0xFF182740),
  ),
  _TokenPair(
    (colors) => colors.line,
    const Color(0xFFE1E7EF),
    const Color(0xFF22324D),
  ),
  _TokenPair(
    (colors) => colors.lineStrong,
    const Color(0xFFCFD8E4),
    const Color(0xFF2C3F5F),
  ),
  _TokenPair(
    (colors) => colors.lineHover,
    const Color(0xFFB1BDCD),
    const Color(0xFF42587C),
  ),
  _TokenPair(
    (colors) => colors.again,
    const Color(0xFFB3261E),
    const Color(0xFFFF8A7F),
  ),
  _TokenPair(
    (colors) => colors.hard,
    const Color(0xFFA05A00),
    const Color(0xFFF2B55E),
  ),
  _TokenPair(
    (colors) => colors.good,
    const Color(0xFF1C7C54),
    const Color(0xFF5ED3A0),
  ),
  _TokenPair(
    (colors) => colors.danger,
    const Color(0xFFB3261E),
    const Color(0xFFFF8A7F),
  ),
  _TokenPair(
    (colors) => colors.dangerSurface,
    const Color(0xFFFDF0EF),
    const Color(0xFF331A26),
  ),
  _TokenPair(
    (colors) => colors.success,
    const Color(0xFF1C7C54),
    const Color(0xFF5ED3A0),
  ),
  _TokenPair(
    (colors) => colors.paper,
    const Color(0xFFFFFFFF),
    const Color(0xFFE8EDF4),
  ),
  _TokenPair(
    (colors) => colors.paperInk,
    const Color(0xFF141C2B),
    const Color(0xFF141C2B),
  ),
  _TokenPair(
    (colors) => colors.paperInkSecondary,
    const Color(0xFF465063),
    const Color(0xFF465063),
  ),
  _TokenPair(
    (colors) => colors.paperLine,
    const Color(0xFFE1E7EF),
    const Color(0xFFC8D1DE),
  ),
  _TokenPair(
    (colors) => colors.scrim,
    const Color.fromRGBO(20, 28, 43, 0.34),
    const Color.fromRGBO(3, 7, 16, 0.66),
  ),
];

void main() {
  test('DesignColors property each token holds its CSS light-dark pair', () {
    forAll((random) => oneOf(random, _cssPairs), (pair) {
      final light = DesignColors.forBrightness(Brightness.light);
      final dark = DesignColors.forBrightness(Brightness.dark);

      expect(pair.read(light), pair.light);
      expect(pair.read(dark), pair.dark);
    });
  });

  testWidgets('DesignColors property follows the theme brightness', (
    tester,
  ) async {
    for (final brightness in examplesOf(
      (random) => oneOf(random, Brightness.values),
      runs: 6,
    )) {
      late DesignColors seen;

      await tester.pumpWidget(
        Theme(
          data: ThemeData(brightness: brightness),
          child: Builder(
            builder: (context) {
              seen = DesignColors.of(context);

              return const SizedBox();
            },
          ),
        ),
      );

      expect(seen, same(DesignColors.forBrightness(brightness)));
    }
  });
}
