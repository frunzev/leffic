import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_shadows.dart';

import '../../support/property.dart';

typedef _CssShadow = ({
  double offsetY,
  double blur,
  double spread,
  Color color,
});

List<_CssShadow> _cssOrderOf(List<BoxShadow> paintedShadows) {
  final cssOrder = <_CssShadow>[];

  for (final shadow in paintedShadows.reversed) {
    expect(shadow, isA<CssBoxShadow>());
    expect(shadow.offset.dx, 0);

    cssOrder.add((
      offsetY: shadow.offset.dy,
      blur: (shadow as CssBoxShadow).cssBlur,
      spread: shadow.spreadRadius,
      color: shadow.color,
    ));
  }

  return cssOrder;
}

const Color _lightShade = Color.fromRGBO(20, 28, 43, 0.05);
const Color _darkShade = Color.fromRGBO(2, 6, 14, 0.4);

void main() {
  test('CssBoxShadow property blurs with half the CSS blur radius', () {
    forAll((random) => integerBetween(random, 0, 4000) / 16, (cssBlur) {
      final shadow = CssBoxShadow(
        color: const Color(0xFF000000),
        cssBlur: cssBlur,
      );

      expect(shadow.blurSigma, cssBlur / 2);
      expect(shadow.blurRadius, cssBlur);
    });
  });

  test('DesignShadows property light shadows equal app-tokens.css', () {
    final shadows = DesignShadows.forBrightness(Brightness.light);
    final colors = DesignColors.forBrightness(Brightness.light);

    expect(shadows.edgeHighlight, const Color(0x00000000));
    expect(_cssOrderOf(shadows.raised), [
      (offsetY: 1.0, blur: 1.0, spread: 0.0, color: _lightShade),
    ]);
    expect(_cssOrderOf(shadows.level2), [
      (offsetY: 1.0, blur: 2.0, spread: 0.0, color: _lightShade),
      (
        offsetY: 16.0,
        blur: 40.0,
        spread: -16.0,
        color: const Color.fromRGBO(20, 28, 43, 0.16),
      ),
    ]);
    expect(_cssOrderOf(shadows.level3), [
      (
        offsetY: 28.0,
        blur: 56.0,
        spread: -16.0,
        color: const Color.fromRGBO(20, 28, 43, 0.3),
      ),
    ]);
    expect(_cssOrderOf(shadows.brand), [
      (
        offsetY: 1.0,
        blur: 2.0,
        spread: 0.0,
        color: const Color.fromRGBO(26, 111, 212, 0.24),
      ),
      (
        offsetY: 8.0,
        blur: 20.0,
        spread: -10.0,
        color: const Color.fromRGBO(26, 111, 212, 0.5),
      ),
    ]);
    expect(_cssOrderOf(shadows.focusRing), [
      (offsetY: 0.0, blur: 0.0, spread: 3.0, color: colors.brandSurfaceStrong),
    ]);
  });

  test('DesignShadows property dark shadows equal app-tokens.css', () {
    final shadows = DesignShadows.forBrightness(Brightness.dark);
    final colors = DesignColors.forBrightness(Brightness.dark);

    expect(shadows.edgeHighlight, const Color.fromRGBO(174, 205, 245, 0.07));
    expect(_cssOrderOf(shadows.raised), [
      (
        offsetY: 1.0,
        blur: 1.0,
        spread: 0.0,
        color: const Color.fromRGBO(2, 6, 14, 0.3),
      ),
    ]);
    expect(_cssOrderOf(shadows.level2), [
      (offsetY: 1.0, blur: 2.0, spread: 0.0, color: _darkShade),
      (
        offsetY: 16.0,
        blur: 40.0,
        spread: -16.0,
        color: const Color.fromRGBO(2, 6, 14, 0.8),
      ),
    ]);
    expect(_cssOrderOf(shadows.level3), [
      (
        offsetY: 28.0,
        blur: 56.0,
        spread: -16.0,
        color: const Color.fromRGBO(2, 6, 14, 0.9),
      ),
    ]);
    expect(_cssOrderOf(shadows.brand), [
      (offsetY: 1.0, blur: 2.0, spread: 0.0, color: _darkShade),
      (
        offsetY: 8.0,
        blur: 20.0,
        spread: -10.0,
        color: const Color.fromRGBO(77, 148, 238, 0.55),
      ),
    ]);
    expect(_cssOrderOf(shadows.focusRing), [
      (offsetY: 0.0, blur: 0.0, spread: 3.0, color: colors.brandSurfaceStrong),
    ]);
  });

  testWidgets('DesignShadows property follows the theme brightness', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      late DesignShadows seen;

      await tester.pumpWidget(
        Theme(
          data: ThemeData(brightness: brightness),
          child: Builder(
            builder: (context) {
              seen = DesignShadows.of(context);

              return const SizedBox();
            },
          ),
        ),
      );

      expect(seen, same(DesignShadows.forBrightness(brightness)));
    }
  });
}
