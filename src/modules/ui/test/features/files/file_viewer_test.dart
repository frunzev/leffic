import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/files/file_viewer.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_shadows.dart';
import 'package:leffic/shared/design/surface_box.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

const Key _documentKey = Key('document');

void main() {
  testWidgets('FileViewer property centres the paper page of the CSS', (
    tester,
  ) async {
    for (final (size, brightness) in examplesOf(
      (random) => (
        Size(
          integerBetween(random, 500, 1600).toDouble(),
          integerBetween(random, 400, 1000).toDouble(),
        ),
        oneOf(random, Brightness.values),
      ),
      runs: 10,
    )) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final colors = DesignColors.forBrightness(brightness);
      final shadows = DesignShadows.forBrightness(brightness);

      await tester.pumpWidget(
        hostedInTheme(
          const FileViewer(document: SizedBox.expand(key: _documentKey)),
          brightness: brightness,
        ),
      );

      final backdrop = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(FileViewer),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      final paperFinder = find.byType(SurfaceBox);
      final paper = tester.widget<SurfaceBox>(paperFinder);
      final paperBox = tester.getRect(paperFinder);
      final documentBox = tester.getRect(find.byKey(_documentKey));
      final paperWidth = size.width - 32 < 680 ? size.width - 32 : 680.0;

      expect(backdrop.color, colors.surfaceTertiary);
      expect(paper.look.fill, colors.paper);
      expect(paper.look.border.color, colors.paperLine);
      expect(paper.look.shadows, shadows.level2);
      expect(paper.borderRadius, 8);
      expect(paperBox.width, paperWidth);
      expect(paperBox.left, (size.width - paperWidth) / 2);
      expect(paperBox.top, 24);
      expect(paperBox.bottom, size.height - 24);
      expect(documentBox, paperBox.deflate(1));
    }
  });
}
