import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/settings/chat_engine_row.dart';
import 'package:leffic/features/settings/ruled_block.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/segmented_control.dart';
import 'package:leffic/shared/settings/chat_engine_choice.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const double _rowWidth = 526;

void main() {
  testWidgets('ChatEngineRow property offers both engines, current marked', (
    tester,
  ) async {
    for (final (selected, chosen) in examplesOf(
      (random) => (
        oneOf(random, ChatEngineChoice.values),
        oneOf(random, ChatEngineChoice.values),
      ),
      runs: 8,
    )) {
      final choices = <ChatEngineChoice>[];

      await tester.pumpWidget(
        hostedPlainly(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: _rowWidth,
              child: ChatEngineRow(selected: selected, onSelected: choices.add),
            ),
          ),
        ),
      );

      final control = tester.widget<SegmentedControl<ChatEngineChoice>>(
        find.byType(SegmentedControl<ChatEngineChoice>),
      );

      await tester.tap(find.text(chosen.label));

      expect(control.choices, [
        ChatEngineChoice.claudeCode,
        ChatEngineChoice.openAi,
      ]);
      expect(control.selected, selected);
      expect(control.size, SegmentedSize.regular);
      expect(choices, chosen == selected ? isEmpty : [chosen]);
    }
  });

  testWidgets('ChatEngineRow property is laid out like .settings-row', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    await tester.pumpWidget(
      hostedPlainly(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: _rowWidth,
            child: ChatEngineRow(
              selected: ChatEngineChoice.claudeCode,
              onSelected: (engine) {},
            ),
          ),
        ),
      ),
    );

    final row = tester.getRect(find.byType(RuledBlock));
    final label = tester.getRect(find.text('AI engine'));
    final value = tester.getRect(find.text(chatEngineRestartNote));
    final control = tester.getRect(
      find.byType(SegmentedControl<ChatEngineChoice>),
    );
    final labelStyle = renderedStyleOf(tester, 'AI engine');
    final valueStyle = renderedStyleOf(tester, chatEngineRestartNote);
    final labelBlockCentre = (label.top + value.bottom) / 2;

    expect(label.left, row.left);
    expect(label.top - row.top, 17);
    expect(value.top - label.bottom, 4);
    expect(control.right, row.right);
    expect(control.center.dy, closeTo(labelBlockCentre, 0.5));
    expect(labelStyle.fontSize, 16);
    expect(labelStyle.color, colors.ink);
    expect(valueStyle.fontSize, 14);
    expect(valueStyle.color, colors.inkTertiary);
  });
}
