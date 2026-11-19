import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/folders/folder_column.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

const double _viewportHeight = 900;
const Size _surface = Size(2600, 1000);

typedef _ColumnExample = ({double width, List<double> heights});

Key _childKey(int index) => ValueKey('child $index');

_ColumnExample _generatedColumn(Random random) {
  final count = integerBetween(random, 2, 5);

  return (
    width: integerBetween(random, 700, 2400).toDouble(),
    heights: [
      for (var index = 0; index < count; index++)
        integerBetween(random, 500, 700).toDouble(),
    ],
  );
}

void main() {
  testWidgets('FolderColumn property fills the page height like .page', (
    tester,
  ) async {
    tester.view.physicalSize = _surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final example in examplesOf(_generatedColumn, runs: 4)) {
      await tester.pumpWidget(
        hostedInLightTheme(
          Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints.loose(
                Size(example.width, _viewportHeight),
              ),
              child: const FolderColumn(children: [SizedBox(height: 40)]),
            ),
          ),
        ),
      );

      final area = tester.getSize(find.byType(FolderColumn));

      expect(area, Size(example.width, _viewportHeight));
    }
  });

  testWidgets('FolderColumn property centres a 920px .folder column', (
    tester,
  ) async {
    tester.view.physicalSize = _surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final example in examplesOf(_generatedColumn, runs: 12)) {
      final heights = example.heights;

      await tester.pumpWidget(
        hostedInLightTheme(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: example.width,
              height: _viewportHeight,
              child: FolderColumn(
                children: [
                  for (var index = 0; index < heights.length; index++)
                    SizedBox(key: _childKey(index), height: heights[index]),
                ],
              ),
            ),
          ),
        ),
      );

      final area = tester.getRect(find.byType(FolderColumn));
      final columnWidth = min(920.0, example.width);
      final first = tester.getRect(find.byKey(_childKey(0)));
      final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
      var contentHeight = 48.0 + 64 + 32 * (heights.length - 1);

      for (final height in heights) {
        contentHeight += height;
      }

      expect(first.left - area.left, (example.width - columnWidth) / 2 + 32);
      expect(first.width, columnWidth - 64);
      expect(first.top - area.top, 48);
      expect(
        scroll.position.maxScrollExtent,
        closeTo(contentHeight - _viewportHeight, 0.01),
      );

      for (var index = 1; index < heights.length; index++) {
        final above = tester.getRect(find.byKey(_childKey(index - 1)));
        final below = tester.getRect(find.byKey(_childKey(index)));

        expect(below.top - above.bottom, 32);
      }
    }
  });
}
