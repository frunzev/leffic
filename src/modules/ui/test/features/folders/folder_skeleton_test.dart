import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/folders/folder_skeleton.dart';
import 'package:leffic/features/folders/shimmer_bar.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/meter.dart';
import 'package:leffic/shared/design/surface_box.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

const List<({double name, double meta, bool hasBadge})> _cssRows = [
  (name: 0.46, meta: 0.24, hasBadge: false),
  (name: 0.62, meta: 0.18, hasBadge: true),
  (name: 0.38, meta: 0.22, hasBadge: true),
  (name: 0.54, meta: 0.16, hasBadge: false),
];

Widget _inColumn(Widget child) {
  return Align(
    alignment: Alignment.topCenter,
    child: SizedBox(width: 856, child: child),
  );
}

Finder _barsIn(Finder area) {
  return find.descendant(of: area, matching: find.byType(ShimmerBar));
}

Finder _blocksIn(Finder area) {
  return find.descendant(of: area, matching: find.byType(SkeletonBlock));
}

void main() {
  testWidgets('UnitsSkeleton property draws four .skeleton-row rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      hostedInLightTheme(_inColumn(const UnitsSkeleton())),
    );

    final rows = find.byType(SkeletonRow);
    final list = tester.getRect(find.byType(SurfaceBox));
    final surface = tester.widget<SurfaceBox>(find.byType(SurfaceBox));
    final headBars = find.descendant(
      of: find.byType(UnitsSkeleton),
      matching: find.byType(ShimmerBar),
    );
    final colors = DesignColors.forBrightness(Brightness.light);

    expect(rows, findsNWidgets(_cssRows.length));
    expect(list.height, _cssRows.length * 52 + 2);
    expect(surface.borderRadius, 14);
    expect(surface.look.border, BorderSide(color: colors.line));
    expect(surface.look.shadows, isEmpty);
    expect(tester.getSize(headBars.at(0)), const Size(64, 12));
    expect(tester.getSize(headBars.at(1)), const Size(80, 12));
    expect(list.top - tester.getRect(headBars.at(0)).bottom, 12);

    for (var index = 0; index < _cssRows.length; index++) {
      final css = _cssRows[index];
      final row = tester.getRect(rows.at(index));
      final bars = _barsIn(rows.at(index));
      final blocks = _blocksIn(rows.at(index));
      final dot = tester.getRect(blocks.at(0));
      final name = tester.getRect(bars.at(0));
      final meta = tester.getRect(bars.at(1));
      final linesWidth = row.width - 16 - 20 - 12 - 16;
      final badgeSpace = css.hasBadge ? 56 + 12 : 0;

      expect(row.height, index == _cssRows.length - 1 ? 52 : 51);
      expect(dot, Rect.fromLTWH(row.left + 16, row.center.dy - 10, 20, 20));
      expect(name.left - dot.right, 12);
      expect(name.height, 12);
      expect(meta.top - name.bottom, 4);
      expect(name.width, closeTo((linesWidth - badgeSpace) * css.name, 0.01));
      expect(meta.width, closeTo((linesWidth - badgeSpace) * css.meta, 0.01));
      expect(blocks, findsNWidgets(css.hasBadge ? 2 : 1));

      if (css.hasBadge) {
        final badge = tester.getRect(blocks.at(1));

        expect(badge.size, const Size(56, 20));
        expect(row.right - badge.right, 16);
      }
    }
  });

  testWidgets('DueSkeleton property mirrors the .due card', (tester) async {
    await tester.pumpWidget(hostedInLightTheme(_inColumn(const DueSkeleton())));

    final card = tester.getRect(find.byType(DueSkeleton));
    final bars = _barsIn(find.byType(DueSkeleton));
    final meter = tester.getRect(find.byType(Meter));
    final button = tester.getRect(bars.at(3));

    expect(tester.widget<Meter>(find.byType(Meter)).fraction, 0);
    expect(
      tester.getRect(bars.at(0)),
      Rect.fromLTWH(card.left + 25, card.top + 25, 88, 12),
    );
    expect(tester.getSize(bars.at(1)), const Size(104, 12));
    expect(card.right - tester.getRect(bars.at(1)).right, 25);
    expect(meter.top - tester.getRect(bars.at(0)).bottom, 8);
    expect(tester.getSize(bars.at(2)), const Size(260, 12));
    expect(button.size, const Size(148, 44));
    expect(tester.widget<ShimmerBar>(bars.at(3)).borderRadius, 10);
    expect(button.top - meter.bottom, 16);
    expect(card.bottom - button.bottom, 25);
    expect(card.right - button.right, 25);
  });

  testWidgets('SkeletonBlock property is a still surface-3 block', (
    tester,
  ) async {
    for (final example in examplesOf(
      (random) => (
        size: Size(
          integerBetween(random, 4, 80).toDouble(),
          integerBetween(random, 4, 40).toDouble(),
        ),
        radius: integerBetween(random, 0, 20).toDouble(),
        brightness: oneOf(random, Brightness.values),
      ),
      runs: 6,
    )) {
      await tester.pumpWidget(
        hostedInTheme(
          Center(
            child: SkeletonBlock(
              size: example.size,
              borderRadius: example.radius,
            ),
          ),
          brightness: example.brightness,
        ),
      );

      final block = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(SkeletonBlock),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = block.decoration as BoxDecoration;

      expect(tester.getSize(find.byType(SkeletonBlock)), example.size);
      expect(
        decoration.color,
        DesignColors.forBrightness(example.brightness).surfaceTertiary,
      );
      expect(decoration.borderRadius, BorderRadius.circular(example.radius));
      expect(tester.hasRunningAnimations, isFalse);
    }
  });

  testWidgets('SkeletonRow property sizes its bars from the free width', (
    tester,
  ) async {
    for (final example in examplesOf(
      (random) => (
        name: integerBetween(random, 10, 90) / 100,
        meta: integerBetween(random, 10, 90) / 100,
        width: integerBetween(random, 300, 700).toDouble(),
      ),
      runs: 6,
    )) {
      await tester.pumpWidget(
        hostedInLightTheme(
          Center(
            child: SizedBox(
              width: example.width,
              child: SkeletonRow(
                nameWidthFactor: example.name,
                metaWidthFactor: example.meta,
              ),
            ),
          ),
        ),
      );

      final bars = find.byType(ShimmerBar);
      final linesWidth = example.width - 16 - 20 - 12 - 16;

      expect(
        tester.getSize(bars.at(0)).width,
        closeTo(linesWidth * example.name, 0.01),
      );
      expect(
        tester.getSize(bars.at(1)).width,
        closeTo(linesWidth * example.meta, 0.01),
      );
    }
  });
}
