import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/settings/ruled_block.dart';
import 'package:leffic/features/settings/secure_note.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/icons/design_icon.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const double _blockWidth = 526;
const Key _contentKey = Key('block content');

Widget _sized(Widget block) {
  return hostedPlainly(
    Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: _blockWidth, child: block),
    ),
  );
}

void main() {
  testWidgets('RuledBlock property starts 16 below a line on top', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final contentHeight in examplesOf(
      (random) => integerBetween(random, 1, 200).toDouble(),
      runs: 5,
    )) {
      await tester.pumpWidget(
        _sized(
          RuledBlock(
            child: SizedBox(key: _contentKey, height: contentHeight),
          ),
        ),
      );

      final block = tester.getRect(find.byType(RuledBlock));
      final content = tester.getRect(find.byKey(_contentKey));
      final box = tester.widget<Container>(
        find.descendant(
          of: find.byType(RuledBlock),
          matching: find.byType(Container),
        ),
      );
      final decoration = box.decoration! as BoxDecoration;

      expect(content.top - block.top, 17);
      expect(block.height, contentHeight + 17);
      expect(content.width, _blockWidth);
      expect(decoration.border, Border(top: BorderSide(color: colors.line)));
    }
  });

  testWidgets('SecureNote property is the .secure-note box', (tester) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final (text, iconColor) in examplesOf(
      (random) => (
        'Note ${wordOf(random)}',
        oneOf(random, [colors.success, colors.danger]),
      ),
      runs: 5,
    )) {
      await tester.pumpWidget(
        _sized(
          SecureNote(
            icon: DesignIcons.success,
            iconColor: iconColor,
            children: [Text(text), const Text('second line')],
          ),
        ),
      );

      final note = tester.getRect(find.byType(SecureNote));
      final icon = tester.getRect(find.byType(DesignIcon));
      final shownText = tester.getRect(find.text(text));
      final secondLine = tester.getRect(find.text('second line'));
      final textStyle = renderedStyleOf(tester, text);
      final box = tester.widget<Container>(
        find.descendant(
          of: find.byType(SecureNote),
          matching: find.byType(Container),
        ),
      );
      final decoration = box.decoration! as BoxDecoration;

      expect(icon.left - note.left, 17);
      expect(icon.top - note.top, 17);
      expect(icon.size, const Size.square(18));
      expect(
        tester.widget<DesignIcon>(find.byType(DesignIcon)).color,
        iconColor,
      );
      expect(shownText.left - icon.right, 12);
      expect(shownText.top - note.top, 13);
      expect(secondLine.top - shownText.bottom, 8);
      expect(note.bottom - secondLine.bottom, 13);
      expect(textStyle.fontSize, 14);
      expect(textStyle.color, colors.inkSecondary);
      expect(decoration.color, colors.surfaceSecondary);
      expect(decoration.border, Border.all(color: colors.line));
      expect(decoration.borderRadius, BorderRadius.circular(10));
    }
  });
}
