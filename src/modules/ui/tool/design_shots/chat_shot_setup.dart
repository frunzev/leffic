import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leffic/features/chat/chat_conversation.dart';
import 'package:leffic/shared/api/chat_api.dart';

import 'shot_backend.dart';

const String _designQuestion = 'What triggers an action potential?';
const String _designAnswer =
    'A depolarisation that pushes the membrane past its threshold, roughly '
    '−55 mV. Below that the channels stay shut and nothing fires.';
const int _unavailableStatus = 503;
const String _unavailableBody =
    '{"detail": "Claude Code is not signed in on this Mac."}';

typedef ConversationSetUp = Future<void> Function(
  WidgetTester tester,
  ChatConversation conversation,
);

ChatApi _chatApiAnswering(ShotReply reply) {
  return ChatApi(shotApiClient(reply));
}

Future<http.Response> _designReply(http.Request request) async {
  return shotJsonReply({'answer': _designAnswer});
}

Future<http.Response> _unavailableReply(http.Request request) async {
  return http.Response(_unavailableBody, _unavailableStatus);
}

Future<void> askAnswered(
  WidgetTester tester,
  ChatConversation conversation,
) async {
  await tester.runAsync(
    () => conversation.ask(
      _designQuestion,
      chatApi: _chatApiAnswering(_designReply),
    ),
  );
}

Future<void> askRefused(
  WidgetTester tester,
  ChatConversation conversation,
) async {
  await tester.runAsync(
    () => conversation.ask(
      _designQuestion,
      chatApi: _chatApiAnswering(_unavailableReply),
    ),
  );
}

Future<void> askPending(
  WidgetTester tester,
  ChatConversation conversation,
) async {
  unawaited(
    conversation.ask(
      _designQuestion,
      chatApi: _chatApiAnswering(shotNeverReply),
    ),
  );
}

Future<void> askNothing(
  WidgetTester tester,
  ChatConversation conversation,
) async {}
