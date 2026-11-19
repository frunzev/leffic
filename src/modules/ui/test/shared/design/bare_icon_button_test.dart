import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/bare_icon_button.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/icons/design_icon.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';
import 'package:leffic/shared/design/surface_box.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

const Color _transparent = Color(0x00000000);
const Color _hoverFill = Color(0xFF112233);
const Color _hoverInk = Color(0xFF445566);

SurfaceBox _surfaceOf(WidgetTester tester) {
  return tester.widget<SurfaceBox>(
    find.descendant(
      of: find.byType(BareIconButton),
      matching: find.byType(SurfaceBox),
    ),
  );
}

void main() {
  testWidgets('BareIconButton property lights up only under the pointer', (
    tester,
  ) async {
    for (final (icon, side) in examplesOf(
      (random) => (
        oneOf(random, DesignIcons.values),
        integerBetween(random, 24, 40).toDouble(),
      ),
      runs: 6,
    )) {
      final colors = DesignColors.forBrightness(Brightness.light);
      var presses = 0;

      await tester.pumpWidget(
        hostedInLightTheme(
          Center(
            child: BareIconButton(
              icon: icon,
              semanticLabel: 'Remove ${icon.name}',
              side: side,
              hoverFill: _hoverFill,
              hoverInk: _hoverInk,
              onPressed: () => presses++,
            ),
          ),
        ),
      );

      final button = find.byType(BareIconButton);
      final glyph = find.byType(DesignIcon);

      expect(tester.getSize(button), Size.square(side));
      expect(tester.getSize(glyph), const Size.square(18));
      expect(tester.getCenter(glyph), tester.getCenter(button));
      expect(tester.widget<DesignIcon>(glyph).color, colors.inkTertiary);
      expect(_surfaceOf(tester).look.fill, _transparent);
      expect(_surfaceOf(tester).borderRadius, 8);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);

      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(button));
      await tester.pump();

      expect(tester.widget<DesignIcon>(glyph).color, _hoverInk);
      expect(_surfaceOf(tester).look.fill, _hoverFill);

      await tester.tap(find.bySemanticsLabel('Remove ${icon.name}'));
      await mouse.removePointer();

      expect(presses, 1);
    }
  });
}
