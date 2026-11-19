import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/files/file_stage.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

const Key _barKey = Key('bar');
const Key _contentKey = Key('content');

void main() {
  testWidgets('FileStage property gives the content all space under the bar', (
    tester,
  ) async {
    for (final (size, barHeight) in examplesOf(
      (random) => (
        Size(
          integerBetween(random, 400, 1600).toDouble(),
          integerBetween(random, 300, 1000).toDouble(),
        ),
        integerBetween(random, 20, 120).toDouble(),
      ),
      runs: 8,
    )) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        hostedPlainly(
          FileStage(
            bar: SizedBox(key: _barKey, height: barHeight),
            content: const SizedBox.expand(key: _contentKey),
          ),
        ),
      );

      final barBox = tester.getRect(find.byKey(_barKey));
      final contentBox = tester.getRect(find.byKey(_contentKey));

      expect(barBox, Offset.zero & Size(size.width, barHeight));
      expect(contentBox, Rect.fromLTRB(0, barHeight, size.width, size.height));
    }
  });
}
