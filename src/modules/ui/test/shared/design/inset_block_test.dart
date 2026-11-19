import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/inset_block.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

const Key _contentKey = Key('inset content');

void main() {
  testWidgets('InsetBlock property pads a surface-2 block like the CSS', (
    tester,
  ) async {
    for (final (contentSize, brightness) in examplesOf(
      (random) => (
        Size(
          integerBetween(random, 10, 300).toDouble(),
          integerBetween(random, 10, 120).toDouble(),
        ),
        oneOf(random, Brightness.values),
      ),
      runs: 8,
    )) {
      final colors = DesignColors.forBrightness(brightness);

      await tester.pumpWidget(
        hostedInTheme(
          Center(
            child: InsetBlock(
              child: SizedBox.fromSize(key: _contentKey, size: contentSize),
            ),
          ),
          brightness: brightness,
        ),
      );

      final block = tester.getRect(find.byType(InsetBlock));
      final content = tester.getRect(find.byKey(_contentKey));
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(InsetBlock),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final decoration = box.decoration as BoxDecoration;

      expect(content.left - block.left, 17);
      expect(content.top - block.top, 13);
      expect(block.size, Size(contentSize.width + 34, contentSize.height + 26));
      expect(decoration.color, colors.surfaceSecondary);
      expect(decoration.border, Border.all(color: colors.line));
      expect(decoration.borderRadius, BorderRadius.circular(10));
    }
  });
}
