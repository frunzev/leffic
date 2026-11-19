import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leffic/features/chat/ask_panel.dart';
import 'package:leffic/features/chat/chat_conversation.dart';
import 'package:leffic/features/chat/chat_failure.dart';
import 'package:leffic/shared/design/button_look.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_shadows.dart';
import 'package:leffic/shared/design/icons/design_icon.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';
import 'package:leffic/shared/widgets/ask_panel_scope.dart';

import '../../shared/api/chat_fakes.dart';
import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const Size _panelSize = Size(380, 900);

class _PanelParts {
  _PanelParts() {
    askPanel.open();
  }

  final ChatConversation conversation = ChatConversation();
  final TextEditingController draft = TextEditingController();
  final AskPanelController askPanel = AskPanelController();

  Widget panel() {
    return AskPanelScope(
      controller: askPanel,
      panel: const SizedBox.shrink(),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox.fromSize(
          size: _panelSize,
          child: AskPanel(
            key: UniqueKey(),
            conversation: conversation,
            draft: draft,
          ),
        ),
      ),
    );
  }

  void dispose() {
    conversation.dispose();
    draft.dispose();
    askPanel.dispose();
  }
}

Future<void> _pumpPanel(
  WidgetTester tester,
  FakeBackend backend,
  _PanelParts parts,
) async {
  await tester.pumpWidget(
    hostedWithBackend(
      client: backend.client(),
      child: Scaffold(body: parts.panel()),
      opened: [],
    ),
  );
}

Finder _iconButton(DesignIcons icon) {
  return find.byWidgetPredicate(
    (widget) => widget is DesignIconButton && widget.icon == icon,
  );
}

Future<void> _ask(WidgetTester tester, String question) async {
  await tester.enterText(find.byType(TextField), question);
  await tester.tap(find.bySemanticsLabel('Send'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('AskPanel property sends the whole conversation every time', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final questions = examplesOf(
      (random) => 'Question ${wordOf(random)}',
      runs: 3,
    );
    final backend = FakeBackend({
      '/chat': (request) async {
        final asked = sentConversation(request).length;

        return jsonReply({'answer': 'Answer number $asked'});
      },
    });
    final parts = _PanelParts();

    await _pumpPanel(tester, backend, parts);

    for (final question in questions) {
      await _ask(tester, question);
    }

    final lastConversation = sentConversation(backend.received.last);

    expect(backend.received.length, questions.length);
    expect(lastConversation.length, questions.length * 2 - 1);

    for (final question in questions) {
      expect(find.text(question), findsOneWidget);
    }

    expect(
      find.text('Answer number ${lastConversation.length}'),
      findsOneWidget,
    );
    parts.dispose();
  });

  testWidgets('AskPanel property thinks and stops sending until answered', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final pendingReply = Completer<http.Response>();
    final backend = FakeBackend({'/chat': (request) => pendingReply.future});
    final parts = _PanelParts();

    await _pumpPanel(tester, backend, parts);
    await tester.enterText(find.byType(TextField), 'Why?');
    await tester.tap(find.bySemanticsLabel('Send'));
    await tester.pump();

    final waitingSend = tester.widget<DesignIconButton>(
      _iconButton(DesignIcons.send),
    );

    expect(find.text('Why?'), findsOneWidget);
    expect(find.text('Thinking…'), findsOneWidget);
    expect(waitingSend.onPressed, isNull);

    pendingReply.complete(jsonReply({'answer': 'Because.'}));
    await tester.pumpAndSettle();

    expect(find.text('Thinking…'), findsNothing);
    expect(find.text('Because.'), findsOneWidget);
    parts.dispose();
  });

  testWidgets('AskPanel property explains why the chat could not answer', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final (status, detail) in examplesOf(
      (random) => (
        oneOf(random, [400, 500, 503]),
        'Claude Code did not answer ${wordOf(random)}',
      ),
      runs: 6,
    )) {
      final backend = FakeBackend({'/chat': failWith(status, detail)});
      final shownFailure = status == 503 ? detail : genericChatFailure;
      final parts = _PanelParts();

      await _pumpPanel(tester, backend, parts);
      await _ask(tester, 'Question');

      expect(find.text(shownFailure), findsOneWidget);
      expect(find.text('Thinking…'), findsNothing);
      expect(find.text('Question'), findsOneWidget);
      parts.dispose();
    }
  });

  testWidgets('AskPanel property keeps the talk when it is built again', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final (question, draftText) in examplesOf(
      (random) => ('Question ${wordOf(random)}', 'Draft ${wordOf(random)}'),
      runs: 3,
    )) {
      final backend = FakeBackend({
        '/chat': answerWith({'answer': 'Yes.'}),
      });
      final parts = _PanelParts();

      await _pumpPanel(tester, backend, parts);
      await _ask(tester, question);
      await tester.enterText(find.byType(TextField), draftText);
      await _pumpPanel(tester, backend, parts);
      await tester.pumpAndSettle();

      expect(find.text(question), findsOneWidget);
      expect(find.text('Yes.'), findsOneWidget);
      expect(find.text(draftText), findsOneWidget);
      parts.dispose();
    }
  });

  testWidgets('AskPanel property closes the Ask panel', (tester) async {
    useDesktopSurface(tester);
    final parts = _PanelParts();

    await _pumpPanel(tester, FakeBackend({}), parts);
    await tester.tap(find.bySemanticsLabel('Close Ask'));
    await tester.pump();

    expect(parts.askPanel.isOpen, isFalse);
    parts.dispose();
  });

  testWidgets('AskPanel property is laid out like app-chat.css', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final brightness in Brightness.values) {
      final colors = DesignColors.forBrightness(brightness);
      final shadows = DesignShadows.forBrightness(brightness);
      final parts = _PanelParts();

      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          theme: ThemeData(brightness: brightness),
          home: Scaffold(body: parts.panel()),
        ),
      );

      final panel = tester.getRect(find.byType(AskPanel));
      final title = tester.getRect(find.text('Ask'));
      final titleStyle = renderedStyleOf(tester, 'Ask');
      final titleIcon = find.byWidgetPredicate(
        (widget) =>
            widget is DesignIcon && widget.icon == DesignIcons.chatHeader,
      );
      final closeButton = _iconButton(DesignIcons.closePlain);
      final close = tester.getRect(closeButton);
      final icon = tester.getRect(titleIcon);
      final panelContainers = find.descendant(
        of: find.byType(AskPanel),
        matching: find.byType(Container),
      );
      final panelBox = tester.widget<Container>(panelContainers.first);
      final decoration = panelBox.decoration! as BoxDecoration;
      final edge = panelBox.foregroundDecoration! as BoxDecoration;

      expect(panel.size, _panelSize);
      expect(decoration.color, colors.surface);
      expect(decoration.border, Border(right: BorderSide(color: colors.line)));
      expect(decoration.boxShadow, shadows.level2);
      expect(
        edge.border,
        Border(top: BorderSide(color: shadows.edgeHighlight)),
      );
      expect(icon.left, 16);
      expect(icon.size, const Size.square(18));
      expect(tester.widget<DesignIcon>(titleIcon).color, colors.brand);
      expect(title.left - icon.right, 8);
      expect(titleStyle.fontSize, 14);
      expect(titleStyle.fontWeight, FontWeight.w600);
      expect(close.size, const Size.square(40));
      expect(panel.right - 1 - close.right, 8);
      expect(close.center.dy, closeTo(25.5, 1e-6));
      expect(icon.center.dy, closeTo(25.5, 1e-6));
      expect(
        tester.widget<DesignIconButton>(closeButton).variant,
        ButtonVariant.quiet,
      );
      parts.dispose();
    }
  });
}
