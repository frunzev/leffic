import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_shadows.dart';
import 'package:leffic/shared/design/surface_box.dart';

import '../../support/property.dart';

const Key _contentKey = Key('surface content');

typedef _SurfaceExample = ({
  SurfaceLook look,
  double radius,
  EdgeInsets padding,
});

Color _colorOf(int value) => Color(0xFF000000 | value);

_SurfaceExample _surfaceExampleOf(Random random) {
  final borderWidth = oneOf(random, [0.0, 1.0, 2.0]);
  final border = borderWidth == 0
      ? BorderSide.none
      : BorderSide(
          color: _colorOf(integerBetween(random, 0, 0xFFFFFF)),
          width: borderWidth,
        );

  return (
    look: SurfaceLook(
      fill: _colorOf(integerBetween(random, 0, 0xFFFFFF)),
      border: border,
      shadows: [
        CssBoxShadow(
          color: _colorOf(integerBetween(random, 0, 0xFFFFFF)),
          cssBlur: integerBetween(random, 0, 40).toDouble(),
        ),
      ],
      edgeHighlight: _colorOf(integerBetween(random, 0, 0xFFFFFF)),
    ),
    radius: integerBetween(random, 0, 14).toDouble(),
    padding: EdgeInsets.fromLTRB(
      integerBetween(random, 0, 24).toDouble(),
      integerBetween(random, 0, 24).toDouble(),
      integerBetween(random, 0, 24).toDouble(),
      integerBetween(random, 0, 24).toDouble(),
    ),
  );
}

void main() {
  testWidgets('SurfaceBox property paints the look it is given', (
    tester,
  ) async {
    for (final example in examplesOf(_surfaceExampleOf, runs: 12)) {
      await tester.pumpWidget(
        Center(
          child: SurfaceBox(
            key: UniqueKey(),
            look: example.look,
            borderRadius: example.radius,
            padding: example.padding,
            child: const SizedBox(key: _contentKey, width: 80, height: 30),
          ),
        ),
      );

      final decorated = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(SurfaceBox),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = decorated.decoration as BoxDecoration;

      expect(decoration.color, example.look.fill);
      expect(decoration.border, Border.fromBorderSide(example.look.border));
      expect(decoration.borderRadius, BorderRadius.circular(example.radius));
      expect(decoration.boxShadow, example.look.shadows);
    }
  });

  testWidgets('SurfaceBox property insets content like a border-box', (
    tester,
  ) async {
    for (final example in examplesOf(_surfaceExampleOf, runs: 12)) {
      await tester.pumpWidget(
        Center(
          child: SurfaceBox(
            key: UniqueKey(),
            look: example.look,
            borderRadius: example.radius,
            padding: example.padding,
            child: const SizedBox(key: _contentKey, width: 80, height: 30),
          ),
        ),
      );

      final outer = tester.getRect(find.byType(SurfaceBox));
      final content = tester.getRect(find.byKey(_contentKey));
      final inset = example.padding + EdgeInsets.all(example.look.border.width);

      expect(content.left - outer.left, inset.left);
      expect(content.top - outer.top, inset.top);
      expect(outer.right - content.right, inset.right);
      expect(outer.bottom - content.bottom, inset.bottom);
    }
  });

  test('edgeHighlightBand property is the top pixel of the padding box', () {
    forAll(
      (random) => (
        Size(
          integerBetween(random, 30, 400).toDouble(),
          integerBetween(random, 30, 200).toDouble(),
        ),
        integerBetween(random, 0, 13).toDouble(),
      ),
      (example) {
        final (size, radius) = example;
        final band = edgeHighlightBand(size, radius);
        final bounds = band.getBounds();

        expect(band.contains(Offset(size.width / 2, 0.5)), isTrue);
        expect(band.contains(Offset(size.width / 2, 1.5)), isFalse);
        expect(band.contains(size.center(Offset.zero)), isFalse);
        expect(bounds.top, 0);
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(size.width));
        expect(bounds.bottom, lessThanOrEqualTo(radius + 1));
      },
    );
  });
}
