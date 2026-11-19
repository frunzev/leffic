import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/widgets/review_stage.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

const Key _contentKey = Key('review content');
const double _stagePadding = 16;
const double _innerMaximumWidth = 720;
const double _innerMaximumHeight = 760;

Size _windowOf(Random random) {
  return Size(
    integerBetween(random, 1024, 1920).toDouble(),
    integerBetween(random, 700, 1200).toDouble(),
  );
}

void _useWindow(WidgetTester tester, Size window) {
  tester.view.physicalSize = window;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('ReviewStage property centres a column at most 720 wide', (
    tester,
  ) async {
    final examples = examplesOf(
      (random) => (_windowOf(random), integerBetween(random, 80, 600)),
      runs: 10,
    );

    for (final (window, contentHeight) in examples) {
      _useWindow(tester, window);

      await tester.pumpWidget(
        hostedPlainly(
          ReviewStage(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(key: _contentKey, height: contentHeight.toDouble()),
              ],
            ),
          ),
        ),
      );

      final content = tester.getRect(find.byKey(_contentKey));
      final expectedWidth = min(
        _innerMaximumWidth,
        window.width - 2 * _stagePadding,
      );

      expect(content.width, expectedWidth);
      expect(content.height, contentHeight);
      expect(content.center.dx, window.width / 2);
      expect(content.center.dy, window.height / 2);
    }
  });

  testWidgets('ReviewStage property caps the column at 760 with 16 inside', (
    tester,
  ) async {
    for (final window in examplesOf(_windowOf, runs: 10)) {
      _useWindow(tester, window);

      await tester.pumpWidget(
        hostedPlainly(
          const ReviewStage(child: SizedBox.expand(key: _contentKey)),
        ),
      );

      final content = tester.getRect(find.byKey(_contentKey));
      final innerHeight = min(
        _innerMaximumHeight,
        window.height - 2 * _stagePadding,
      );

      expect(content.height, innerHeight - 2 * _stagePadding);
      expect(content.center.dy, window.height / 2);
    }
  });
}
