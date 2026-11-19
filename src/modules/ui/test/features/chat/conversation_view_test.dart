import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/chat/chat_bubble.dart';
import 'package:leffic/features/chat/conversation_view.dart';
import 'package:leffic/shared/api/chat_models.dart';
import 'package:leffic/shared/design/design_colors.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const Size _logSize = Size(379, 600);

List<ChatMessage> _numberedConversation(int count) {
  final conversation = <ChatMessage>[];

  for (var index = 0; index < count; index++) {
    final role = index.isEven ? ChatRole.user : ChatRole.assistant;

    conversation.add(ChatMessage(role: role, content: 'message $index'));
  }

  return conversation;
}

Future<void> _pumpLog(WidgetTester tester, ConversationView log) async {
  await tester.pumpWidget(
    hostedPlainly(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox.fromSize(size: _logSize, child: log),
      ),
    ),
  );
}

Rect _bubbleAround(WidgetTester tester, String text) {
  return tester.getRect(
    find.ancestor(of: find.text(text), matching: find.byType(DecoratedBox)),
  );
}

void main() {
  testWidgets('ConversationView property lists messages top down, 12 apart', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final count in examplesOf(
      (random) => integerBetween(random, 1, 6),
      runs: 6,
    )) {
      await _pumpLog(
        tester,
        ConversationView(
          conversation: _numberedConversation(count),
          isWaiting: false,
          failureMessage: null,
        ),
      );

      expect(_bubbleAround(tester, 'message 0').top, 16);

      for (var index = 1; index < count; index++) {
        final earlier = _bubbleAround(tester, 'message ${index - 1}');
        final later = _bubbleAround(tester, 'message $index');

        expect(later.top - earlier.bottom, closeTo(12, 1e-6));
      }

      expect(find.text('Thinking…'), findsNothing);
      expect(find.text('No messages yet'), findsNothing);
    }
  });

  testWidgets('ConversationView property ends with thinking or the failure', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final (count, failure) in examplesOf(
      (random) => (
        integerBetween(random, 1, 5),
        oneOf(random, [null, 'Failure ${wordOf(random)}']),
      ),
      runs: 8,
    )) {
      await _pumpLog(
        tester,
        ConversationView(
          conversation: _numberedConversation(count),
          isWaiting: failure == null,
          failureMessage: failure,
        ),
      );

      final lastLine = failure ?? 'Thinking…';
      final lastBubble = tester.widget<ChatBubble>(
        find.byType(ChatBubble).last,
      );
      final lastTop = _bubbleAround(tester, lastLine).top;

      expect(lastBubble.role, ChatRole.assistant);
      expect(lastBubble.text, lastLine);

      for (var index = 0; index < count; index++) {
        expect(
          lastTop,
          greaterThan(_bubbleAround(tester, 'message $index').top),
        );
      }
    }
  });

  testWidgets('ConversationView property keeps the newest line in view', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final count in examplesOf(
      (random) => integerBetween(random, 30, 60),
      runs: 3,
    )) {
      await _pumpLog(
        tester,
        ConversationView(
          conversation: _numberedConversation(count),
          isWaiting: false,
          failureMessage: null,
        ),
      );

      final newest = _bubbleAround(tester, 'message ${count - 1}');

      expect(newest.bottom, closeTo(_logSize.height - 16, 1e-6));
    }
  });

  testWidgets('ConversationView property says when nothing was asked', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    await _pumpLog(
      tester,
      const ConversationView(
        conversation: [],
        isWaiting: false,
        failureMessage: null,
      ),
    );

    final emptyText = tester.getRect(find.text('No messages yet'));
    final emptyStyle = renderedStyleOf(tester, 'No messages yet');

    expect(emptyText.center.dx, closeTo(_logSize.width / 2, 0.5));
    expect(emptyText.center.dy, closeTo(_logSize.height / 2, 0.5));
    expect(emptyStyle.fontSize, 14);
    expect(emptyStyle.fontWeight, FontWeight.w500);
    expect(emptyStyle.color, colors.inkTertiary);
    expect(find.byType(ChatBubble), findsNothing);
  });
}
