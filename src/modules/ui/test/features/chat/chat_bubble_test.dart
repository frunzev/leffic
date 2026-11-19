import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/chat/chat_bubble.dart';
import 'package:leffic/shared/api/chat_models.dart';
import 'package:leffic/shared/design/design_colors.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const double _logWidth = 347;

Future<void> _pumpBubble(
  WidgetTester tester,
  ChatRole role,
  String text,
) async {
  await tester.pumpWidget(
    hostedPlainly(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: _logWidth,
          child: ChatBubble(role: role, text: text),
        ),
      ),
    ),
  );
}

Finder _bubbleBox() {
  return find.descendant(
    of: find.byType(ChatBubble),
    matching: find.byType(DecoratedBox),
  );
}

BoxDecoration _bubbleDecoration(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(_bubbleBox());

  return box.decoration as BoxDecoration;
}

String _sentence(int wordCount) {
  return List.filled(wordCount, 'membrane').join(' ');
}

void main() {
  testWidgets('ChatBubble property sits on the side of its role', (
    tester,
  ) async {
    for (final (role, text) in examplesOf(
      (random) => (oneOf(random, ChatRole.values), wordOf(random)),
      runs: 8,
    )) {
      await _pumpBubble(tester, role, text);

      final bubble = tester.getRect(_bubbleBox());
      final shownText = tester.getRect(find.text(text));

      expect(find.text(text), findsOneWidget);
      expect(shownText.left - bubble.left, 16);
      expect(shownText.top - bubble.top, 12);
      expect(bubble.bottom - shownText.bottom, 12);

      if (role == ChatRole.user) {
        expect(bubble.right, _logWidth);
      } else {
        expect(bubble.left, 0);
      }
    }
  });

  testWidgets('ChatBubble property never grows past 88% of the log', (
    tester,
  ) async {
    for (final (role, wordCount) in examplesOf(
      (random) =>
          (oneOf(random, ChatRole.values), integerBetween(random, 1, 40)),
      runs: 10,
    )) {
      await _pumpBubble(tester, role, _sentence(wordCount));

      final bubble = tester.getRect(_bubbleBox());

      expect(bubble.width, lessThanOrEqualTo(_logWidth * 0.88 + 1e-6));
    }
  });

  testWidgets('ChatBubble property is coloured and rounded by its role', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final role in ChatRole.values) {
      await _pumpBubble(tester, role, 'Why?');

      final decoration = _bubbleDecoration(tester);
      final textStyle = renderedStyleOf(tester, 'Why?');
      final isFromUser = role == ChatRole.user;
      final corner = const Radius.circular(14);
      final tuckedCorner = const Radius.circular(8);

      expect(
        decoration.color,
        isFromUser ? colors.brand : colors.surfaceTertiary,
      );
      expect(
        decoration.borderRadius,
        BorderRadius.only(
          topLeft: corner,
          topRight: corner,
          bottomLeft: isFromUser ? corner : tuckedCorner,
          bottomRight: isFromUser ? tuckedCorner : corner,
        ),
      );
      expect(textStyle.color, isFromUser ? colors.onBrand : colors.ink);
      expect(textStyle.fontSize, 14);
      expect(textStyle.height, 1.5);
    }
  });
}
