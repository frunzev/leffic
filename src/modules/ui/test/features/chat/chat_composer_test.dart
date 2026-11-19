import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/chat/chat_composer.dart';
import 'package:leffic/shared/design/button_look.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_shadows.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';
import 'package:leffic/shared/design/surface_box.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

const List<String> _paddings = ['', ' ', '\n', '  \t'];
const double _composerWidth = 379;

Future<void> _pumpComposer(
  WidgetTester tester, {
  required TextEditingController draft,
  required ValueChanged<String>? onSend,
}) async {
  await tester.pumpWidget(
    hostedPlainly(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: _composerWidth,
          child: ChatComposer(key: UniqueKey(), draft: draft, onSend: onSend),
        ),
      ),
    ),
  );
}

Finder _sendButton() => find.bySemanticsLabel('Send');

SurfaceLook _composeLook(WidgetTester tester) {
  final box = find.descendant(
    of: find.byType(ChatComposer),
    matching: find.byType(SurfaceBox),
  );

  return tester.widget<SurfaceBox>(box.first).look;
}

void main() {
  testWidgets('ChatComposer property sends the trimmed question once', (
    tester,
  ) async {
    for (final (question, padding, isSentByEnter) in examplesOf(
      (random) => (wordOf(random), oneOf(random, _paddings), random.nextBool()),
      runs: 8,
    )) {
      final sentQuestions = <String>[];
      final draft = TextEditingController();

      await _pumpComposer(tester, draft: draft, onSend: sentQuestions.add);
      await tester.enterText(
        find.byType(TextField),
        '$padding$question$padding',
      );

      if (isSentByEnter) {
        await tester.testTextInput.receiveAction(TextInputAction.send);
      } else {
        await tester.tap(_sendButton());
      }

      await tester.pump();

      expect(sentQuestions, [question]);
      expect(draft.text, isEmpty);
    }
  });

  testWidgets('ChatComposer property never sends a blank question', (
    tester,
  ) async {
    for (final padding in examplesOf(
      (random) => oneOf(random, _paddings),
      runs: 4,
    )) {
      final sentQuestions = <String>[];

      await _pumpComposer(
        tester,
        draft: TextEditingController(),
        onSend: sentQuestions.add,
      );
      await tester.enterText(find.byType(TextField), padding);
      await tester.tap(_sendButton());

      expect(sentQuestions, isEmpty);
    }
  });

  testWidgets('ChatComposer property keeps the draft while sending is off', (
    tester,
  ) async {
    for (final question in examplesOf(wordOf, runs: 4)) {
      final draft = TextEditingController();

      await _pumpComposer(tester, draft: draft, onSend: null);
      await tester.enterText(find.byType(TextField), question);
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      final sendButton = tester.widget<DesignIconButton>(
        find.byType(DesignIconButton),
      );

      expect(sendButton.onPressed, isNull);
      expect(draft.text, question);
    }
  });

  testWidgets('ChatComposer property is laid out like .chatbot-compose', (
    tester,
  ) async {
    final draft = TextEditingController();

    await _pumpComposer(tester, draft: draft, onSend: (question) {});

    final composer = tester.getRect(find.byType(ChatComposer));
    final compose = tester.getRect(
      find
          .descendant(
            of: find.byType(ChatComposer),
            matching: find.byType(SurfaceBox),
          )
          .first,
    );
    final input = tester.getRect(find.byType(TextField));
    final hint = tester.getRect(find.text('Ask a question'));
    final send = tester.getRect(find.byType(DesignIconButton));
    final sendButton = tester.widget<DesignIconButton>(
      find.byType(DesignIconButton),
    );

    expect(compose.left - composer.left, 16);
    expect(composer.right - compose.right, 16);
    expect(compose.top - composer.top, 16);
    expect(composer.bottom - compose.bottom, 16);
    expect(compose.height, 2 + 24 + 76 + 8 + 34);
    expect(input.top - compose.top, 13);
    expect(input.height, 76);
    expect(input.width, compose.width - 26);
    expect(hint.left - compose.left, 15);
    expect(hint.top - compose.top, closeTo(15, 0.5));
    expect(send.size, const Size.square(34));
    expect(compose.right - send.right, 13);
    expect(compose.bottom - send.bottom, 13);
    expect(send.top - input.bottom, 8);
    expect(sendButton.icon, DesignIcons.send);
    expect(sendButton.variant, ButtonVariant.primary);
    expect(sendButton.borderRadius, greaterThanOrEqualTo(17));
  });

  testWidgets('ChatComposer property rings the box while typing', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);
    final shadows = DesignShadows.forBrightness(Brightness.light);

    await _pumpComposer(
      tester,
      draft: TextEditingController(),
      onSend: (question) {},
    );

    final restingLook = _composeLook(tester);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final typingLook = _composeLook(tester);

    expect(restingLook.border, BorderSide(color: colors.lineStrong));
    expect(restingLook.shadows, shadows.raised);
    expect(restingLook.fill, colors.surface);
    expect(typingLook.border, BorderSide(color: colors.brand));
    expect(typingLook.shadows, shadows.focusRing);
  });
}
