import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/chat/ask_panel.dart';
import 'package:leffic/features/chat/chat_conversation.dart';
import 'package:leffic/shared/widgets/ask_panel_scope.dart';

import '../support/backend_fakes.dart';
import '../support/hosting.dart';
import 'requirement_world.dart';
import 'step_definition.dart';

const String _chat = '/chat';
const String _send = 'Send';
const int _unavailableStatus = 503;
const int _refusedStatus = 402;
const Size _panelSize = Size(380, 900);

Future<void> _answerQuestions(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  world.replies[_chat] = answerWith({'answer': values.single});
}

Future<void> _makeAskUnavailable(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  world.replies[_chat] = failWith(_unavailableStatus, values.single);
}

Future<void> _refuseAsk(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  world.replies[_chat] = failWith(_refusedStatus, values.single);
}

Widget _askPanel(
  ChatConversation conversation,
  TextEditingController draft,
  AskPanelController askPanel,
) {
  return AskPanelScope(
    controller: askPanel,
    panel: const SizedBox.shrink(),
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox.fromSize(
        size: _panelSize,
        child: AskPanel(conversation: conversation, draft: draft),
      ),
    ),
  );
}

Future<void> _ask(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final conversation = ChatConversation();
  final draft = TextEditingController();
  final askPanel = AskPanelController()..open();

  addTearDown(conversation.dispose);
  addTearDown(draft.dispose);
  addTearDown(askPanel.dispose);

  await tester.pumpWidget(
    hostedWithBackend(
      client: world.client(),
      opened: [],
      child: Scaffold(body: _askPanel(conversation, draft, askPanel)),
    ),
  );
  await tester.enterText(find.byType(TextField), values.single);
  await tester.tap(find.bySemanticsLabel(_send));
  await tester.pumpAndSettle();
}

final List<StepDefinition> askStepDefinitions = [
  StepDefinition(
    'Given',
    RegExp(r'^Ask answers every question with "(.+)"$'),
    _answerQuestions,
  ),
  StepDefinition(
    'Given',
    RegExp(r'^Ask is unavailable with "(.+)"$'),
    _makeAskUnavailable,
  ),
  StepDefinition('Given', RegExp(r'^Ask is refused with "(.+)"$'), _refuseAsk),
  StepDefinition('When', RegExp(r'^I ask "(.+)" in the app$'), _ask),
];
