import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/icons/design_icon.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';
import 'package:leffic/shared/design/section_label.dart';
import 'package:leffic/shared/design/state_block.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const Key _actionKey = Key('state action');

typedef _StateExample = ({
  DesignIcons icon,
  String title,
  String text,
  bool hasAction,
});

void main() {
  testWidgets('StateBlock property lays out like .state', (tester) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final example in examplesOf<_StateExample>(
      (random) => (
        icon: oneOf(random, DesignIcons.values),
        title: 'Title ${wordOf(random)}',
        text: 'Text ${wordOf(random)}',
        hasAction: random.nextBool(),
      ),
      runs: 10,
    )) {
      await tester.pumpWidget(
        hostedPlainly(
          Align(
            alignment: Alignment.topCenter,
            child: StateBlock(
              icon: example.icon,
              title: example.title,
              text: example.text,
              action: example.hasAction
                  ? const SizedBox(key: _actionKey, width: 100, height: 44)
                  : null,
            ),
          ),
        ),
      );

      final block = tester.getRect(find.byType(StateBlock));
      final icon = tester.getRect(find.byType(DesignIcon));
      final title = tester.getRect(find.text(example.title));
      final text = tester.getRect(find.text(example.text));
      final titleStyle = renderedStyleOf(tester, example.title);
      final textStyle = renderedStyleOf(tester, example.text);
      final iconWidget = tester.widget<DesignIcon>(find.byType(DesignIcon));

      expect(icon.top - block.top, 64);
      expect(icon.size, const Size.square(32));
      expect(iconWidget.color, colors.inkTertiary);
      expect(icon.center.dx, closeTo(block.center.dx, 1e-6));
      expect(title.top - icon.bottom, 12);
      expect(text.top - title.bottom, 12);
      expect(titleStyle.fontSize, 20);
      expect(titleStyle.fontWeight, FontWeight.w600);
      expect(textStyle.fontSize, 14);
      expect(textStyle.color, colors.inkSecondary);

      if (example.hasAction) {
        final action = tester.getRect(find.byKey(_actionKey));

        expect(action.top - text.bottom, 20);
        expect(block.bottom - action.bottom, 64);
      } else {
        expect(block.bottom - text.bottom, 64);
      }
    }
  });

  testWidgets('StateBlock property caps its text at 44 characters wide', (
    tester,
  ) async {
    final longText = List.filled(60, 'word').join(' ');

    await tester.pumpWidget(
      hostedPlainly(StateBlock(title: 'Empty', text: longText)),
    );

    expect(
      tester.getSize(find.text(longText)).width,
      lessThanOrEqualTo(44 * 14 * 0.6298828125),
    );
  });

  testWidgets('SectionLabel property is 14px semibold secondary ink', (
    tester,
  ) async {
    for (final label in examplesOf(wordOf, runs: 4)) {
      await tester.pumpWidget(hostedPlainly(SectionLabel(label)));

      final style = renderedStyleOf(tester, label);

      expect(style.fontSize, 14);
      expect(style.fontWeight, FontWeight.w600);
      expect(
        style.color,
        DesignColors.forBrightness(Brightness.light).inkSecondary,
      );
    }
  });
}
