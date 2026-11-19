import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/notes/note_card.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_shadows.dart';
import 'package:leffic/shared/design/surface_box.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

const Key _contentKey = Key('content');

void main() {
  testWidgets('NoteCard property centres the raised card of the CSS', (
    tester,
  ) async {
    for (final (size, contentHeight, brightness) in examplesOf(
      (random) => (
        Size(
          integerBetween(random, 500, 1800).toDouble(),
          integerBetween(random, 600, 1200).toDouble(),
        ),
        integerBetween(random, 0, 400).toDouble(),
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
          NoteCard(
            child: SizedBox(key: _contentKey, height: contentHeight),
          ),
          brightness: brightness,
        ),
      );

      final card = tester.widget<SurfaceBox>(find.byType(SurfaceBox));
      final cardBox = tester.getRect(find.byType(SurfaceBox));
      final contentBox = tester.getRect(find.byKey(_contentKey));
      final cardWidth = size.width - 32 < 760 ? size.width - 32 : 760.0;

      expect(card.look.fill, colors.surface);
      expect(card.look.border.color, colors.line);
      expect(card.look.shadows, shadows.raised);
      expect(card.look.edgeHighlight, shadows.edgeHighlight);
      expect(card.borderRadius, 14);
      expect(cardBox.top, 40);
      expect(cardBox.width, cardWidth);
      expect(cardBox.left, (size.width - cardWidth) / 2);
      expect(contentBox, cardBox.deflate(49));
    }
  });
}
