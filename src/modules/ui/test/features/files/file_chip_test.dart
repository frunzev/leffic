import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/files/file_chip.dart';
import 'package:leffic/shared/design/design_colors.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

void main() {
  testWidgets('FileChip property draws the pill of the CSS', (tester) async {
    for (final (label, brightness) in examplesOf(
      (random) => (
        wordOf(random, maximum: 5).toUpperCase(),
        oneOf(random, Brightness.values),
      ),
      runs: 6,
    )) {
      final colors = DesignColors.forBrightness(brightness);

      await tester.pumpWidget(
        hostedInTheme(
          Center(child: FileChip(label: label)),
          brightness: brightness,
        ),
      );

      final chipBox = tester.getRect(find.byType(FileChip));
      final labelBox = tester.getRect(find.text(label));
      final pill = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(FileChip),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = pill.decoration as BoxDecoration;
      final style = renderedStyleOf(tester, label);

      expect(decoration.color, colors.surfaceTertiary);
      expect(decoration.borderRadius, BorderRadius.circular(999));
      expect(labelBox.left - chipBox.left, 8);
      expect(labelBox.top - chipBox.top, 2);
      expect(chipBox.height, labelBox.height + 4);
      expect(chipBox.width, labelBox.width + 16);
      expect(style.fontSize, 12);
      expect(style.fontWeight, FontWeight.w500);
      expect(style.color, colors.inkSecondary);
    }
  });
}
