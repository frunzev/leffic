import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leffic/features/chat/chat_conversation.dart';
import 'package:leffic/features/chat/chat_failure.dart';
import 'package:leffic/shared/api/chat_api.dart';
import 'package:leffic/shared/api/chat_models.dart';

import '../../shared/api/chat_fakes.dart';
import '../../support/backend_fakes.dart';
import '../../support/property.dart';

ReplyToRequest _answerNumbered() {
  return (request) async {
    final askedCount = sentConversation(request).length;

    return jsonReply({'answer': 'Answer number $askedCount'});
  };
}

void main() {
  test(
    'ChatConversation property sends the whole conversation each time',
    () async {
      final questionLists = examplesOf(
        (random) => [
          for (var index = 0; index < integerBetween(random, 1, 5); index++)
            'Question ${wordOf(random)}',
        ],
        runs: 8,
      );

      for (final questions in questionLists) {
        final backend = FakeBackend({'/chat': _answerNumbered()});
        final chatApi = ChatApi(backend.client());
        final conversation = ChatConversation();

        for (final question in questions) {
          await conversation.ask(question, chatApi: chatApi);
        }

        final lastSent = sentConversation(backend.received.last);
        final messages = conversation.messages;

        expect(backend.received.length, questions.length);
        expect(lastSent.length, questions.length * 2 - 1);
        expect(messages.length, questions.length * 2);

        for (var index = 0; index < questions.length; index++) {
          final asked = messages[index * 2];
          final answered = messages[index * 2 + 1];

          expect(asked.role, ChatRole.user);
          expect(asked.content, questions[index]);
          expect(answered.role, ChatRole.assistant);
          expect(answered.content, 'Answer number ${index * 2 + 1}');
        }

        expect(conversation.isWaiting, isFalse);
        expect(conversation.failureMessage, isNull);
        conversation.dispose();
      }
    },
  );

  test(
    'ChatConversation property waits while the answer is on its way',
    () async {
      for (final question in examplesOf(wordOf, runs: 5)) {
        final pendingReply = Completer<http.Response>();
        final backend = FakeBackend({
          '/chat': (request) => pendingReply.future,
        });
        final conversation = ChatConversation();
        var notifications = 0;

        conversation.addListener(() => notifications++);

        final asking = conversation.ask(
          question,
          chatApi: ChatApi(backend.client()),
        );

        expect(conversation.isWaiting, isTrue);
        expect(conversation.messages.single.content, question);
        expect(notifications, 1);

        pendingReply.complete(jsonReply({'answer': 'Because.'}));
        await asking;

        expect(conversation.isWaiting, isFalse);
        expect(conversation.messages.last.content, 'Because.');
        expect(notifications, 2);
        conversation.dispose();
      }
    },
  );

  test(
    'ChatConversation property explains a failure until the next ask',
    () async {
      for (final (status, detail) in examplesOf(
        (random) => (
          oneOf(random, [400, 500, 503]),
          'Claude Code did not answer ${wordOf(random)}',
        ),
        runs: 8,
      )) {
        final failing = FakeBackend({'/chat': failWith(status, detail)});
        final answering = FakeBackend({'/chat': _answerNumbered()});
        final conversation = ChatConversation();
        final shownFailure = status == 503 ? detail : genericChatFailure;

        await conversation.ask('Question', chatApi: ChatApi(failing.client()));

        expect(conversation.failureMessage, shownFailure);
        expect(conversation.isWaiting, isFalse);
        expect(conversation.messages.single.content, 'Question');

        await conversation.ask('Again', chatApi: ChatApi(answering.client()));

        expect(conversation.failureMessage, isNull);
        expect(conversation.messages.length, 3);
        conversation.dispose();
      }
    },
  );
}
