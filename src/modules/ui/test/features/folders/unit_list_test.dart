import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/folders/folder_panel.dart';
import 'package:leffic/features/folders/unit_list.dart';
import 'package:leffic/features/folders/unit_presentation.dart';
import 'package:leffic/features/folders/units_head.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_divider.dart';
import 'package:leffic/shared/design/design_shadows.dart';
import 'package:leffic/shared/design/section_label.dart';
import 'package:leffic/shared/design/surface_box.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const double _rowHeight = 52;

Key _rowKey(int index) => ValueKey('row $index');

({int count, int index}) _rowPosition(Random random) {
  final count = integerBetween(random, 1, 30);

  return (count: count, index: random.nextInt(count));
}

void main() {
  test('unitRowCorners property rounds only the outer corners of the list', () {
    forAll(_rowPosition, (example) {
      final corners = unitRowCorners(
        index: example.index,
        count: example.count,
      );
      final isFirst = example.index == 0;
      final isLast = example.index == example.count - 1;

      expect(corners.topLeft.x, isFirst ? 14 : 0);
      expect(corners.topRight.x, isFirst ? 14 : 0);
      expect(corners.bottomLeft.x, isLast ? 14 : 0);
      expect(corners.bottomRight.x, isLast ? 14 : 0);
    });
  });

  test('unitRowCorners property refuses a row outside the list', () {
    forAll((random) => integerBetween(random, 1, 30), (count) {
      expect(
        () => unitRowCorners(index: count, count: count),
        throwsArgumentError,
      );
      expect(
        () => unitRowCorners(index: -1, count: count),
        throwsArgumentError,
      );
    });
  });

  testWidgets('UnitList property frames rows like .units with dividers', (
    tester,
  ) async {
    for (final example in examplesOf(
      (random) => (
        count: integerBetween(random, 1, 8),
        brightness: oneOf(random, Brightness.values),
      ),
      runs: 8,
    )) {
      final colors = DesignColors.forBrightness(example.brightness);
      final shadows = DesignShadows.forBrightness(example.brightness);

      await tester.pumpWidget(
        hostedInTheme(
          SingleChildScrollView(
            child: UnitList(
              rows: [
                for (var index = 0; index < example.count; index++)
                  SizedBox(key: _rowKey(index), height: _rowHeight),
              ],
            ),
          ),
          brightness: example.brightness,
        ),
      );

      final list = tester.getRect(find.byType(UnitList));
      final surface = tester.widget<SurfaceBox>(find.byType(SurfaceBox));
      final dividers = find.byType(DesignDivider);

      expect(dividers, findsNWidgets(example.count - 1));
      expect(list.height, example.count * 53 - 1 + 2);
      expect(tester.getRect(find.byKey(_rowKey(0))).top - list.top, 1);
      expect(surface.borderRadius, 14);
      expect(surface.look.fill, colors.surface);
      expect(surface.look.border, BorderSide(color: colors.line));
      expect(surface.look.shadows, shadows.raised);

      for (var index = 1; index < example.count; index++) {
        final above = tester.getRect(find.byKey(_rowKey(index - 1)));
        final below = tester.getRect(find.byKey(_rowKey(index)));

        expect(below.top - above.bottom, 1);
      }
    }
  });

  test('withDividersBetween property puts one divider between neighbours', () {
    forAll((random) => integerBetween(random, 0, 20), (count) {
      final rows = [
        for (var index = 0; index < count; index++)
          SizedBox(key: _rowKey(index)),
      ];
      final separated = withDividersBetween(rows);

      expect(separated.length, count == 0 ? 0 : 2 * count - 1);

      for (var index = 0; index < separated.length; index++) {
        final isRow = index.isEven;

        expect(separated[index] is DesignDivider, !isRow);

        if (isRow) {
          expect(separated[index], rows[index ~/ 2]);
        }
      }
    });
  });

  testWidgets('FolderPanel property is a raised 14px .due surface', (
    tester,
  ) async {
    for (final example in examplesOf(
      (random) => (
        padding: integerBetween(random, 0, 40).toDouble(),
        brightness: oneOf(random, Brightness.values),
      ),
      runs: 6,
    )) {
      final colors = DesignColors.forBrightness(example.brightness);
      final shadows = DesignShadows.forBrightness(example.brightness);

      await tester.pumpWidget(
        hostedInTheme(
          Center(
            child: FolderPanel(
              padding: EdgeInsets.all(example.padding),
              child: SizedBox(key: _rowKey(0), width: 100, height: 50),
            ),
          ),
          brightness: example.brightness,
        ),
      );

      final panel = tester.getRect(find.byType(FolderPanel));
      final content = tester.getRect(find.byKey(_rowKey(0)));
      final surface = tester.widget<SurfaceBox>(find.byType(SurfaceBox));

      expect(
        content.topLeft - panel.topLeft,
        Offset(example.padding + 1, example.padding + 1),
      );
      expect(
        panel.size,
        Size(100 + 2 * example.padding + 2, 50 + 2 * example.padding + 2),
      );
      expect(surface.borderRadius, 14);
      expect(surface.look.fill, colors.surface);
      expect(surface.look.border, BorderSide(color: colors.line));
      expect(surface.look.shadows, shadows.raised);
      expect(surface.look.edgeHighlight, shadows.edgeHighlight);
    }
  });

  testWidgets('UnitsHead property names the count and the order', (
    tester,
  ) async {
    for (final example in examplesOf(
      (random) => (
        count: integerBetween(random, 0, 300),
        brightness: oneOf(random, Brightness.values),
      ),
      runs: 6,
    )) {
      final colors = DesignColors.forBrightness(example.brightness);
      final countText = itemCountLabel(example.count);

      await tester.pumpWidget(
        hostedInTheme(
          SizedBox(width: 600, child: UnitsHead(count: example.count)),
          brightness: example.brightness,
        ),
      );

      final head = tester.getRect(find.byType(UnitsHead));
      final count = tester.getRect(find.text(countText));
      final note = tester.getRect(find.text('Newest first'));
      final noteStyle = renderedStyleOf(tester, 'Newest first');

      expect(
        tester.widget<SectionLabel>(find.byType(SectionLabel)).text,
        countText,
      );
      expect(count.left, head.left);
      expect(note.right, head.right);
      expect(note.bottom, closeTo(count.bottom, 0.01));
      expect(noteStyle.fontSize, 14);
      expect(noteStyle.color, colors.inkTertiary);
    }
  });
}
