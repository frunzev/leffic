import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/hint_tip.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

double _tipOpacity(WidgetTester tester) {
  final fade = tester.widget<AnimatedOpacity>(
    find.ancestor(
      of: find.byType(HintTipBubble),
      matching: find.byType(AnimatedOpacity),
    ),
  );

  return fade.opacity;
}

void main() {
  testWidgets('HintTip property is an 18px ? that reveals its tip on hover', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final text in examplesOf(
      (random) => 'Tip ${wordOf(random)} ${wordOf(random)}',
      runs: 4,
    )) {
      await tester.pumpWidget(
        hostedPlainly(
          Center(
            child: HintTip(text: text, semanticLabel: 'How it works'),
          ),
        ),
      );

      final button = tester.getRect(find.byType(HintTipButton));
      final markStyle = renderedStyleOf(tester, '?');

      expect(button.size, const Size.square(18));
      expect(markStyle.fontSize, 12);
      expect(markStyle.fontWeight, FontWeight.w600);
      expect(markStyle.color, colors.inkTertiary);
      expect(_tipOpacity(tester), 0);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);

      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(button.center);
      await tester.pumpAndSettle();

      final bubble = tester.getRect(find.byType(HintTipBubble));
      final hoveredMark = renderedStyleOf(tester, '?');
      final textStyle = renderedStyleOf(tester, text);
      final tipText = tester.getRect(find.text(text));

      expect(_tipOpacity(tester), 1);
      expect(hoveredMark.color, colors.brandStrong);
      expect(bubble.width, 232);
      expect(bubble.left - button.left, -8);
      expect(bubble.top - button.bottom, 8);
      expect(tipText.left - bubble.left, 12);
      expect(tipText.top - bubble.top, 8);
      expect(textStyle.fontSize, 12);
      expect(textStyle.height, 1.45);
      expect(textStyle.color, colors.surface);

      await mouse.moveTo(const Offset(2, 2));
      await tester.pumpAndSettle();

      expect(_tipOpacity(tester), 0);

      await mouse.removePointer();
    }
  });

  testWidgets('HintTip property reveals its tip on keyboard focus', (
    tester,
  ) async {
    await tester.pumpWidget(
      hostedPlainly(
        const Center(
          child: HintTip(text: 'Sealed key', semanticLabel: 'How it works'),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(_tipOpacity(tester), 1);
    expect(find.bySemanticsLabel('How it works'), findsOneWidget);
  });
}
