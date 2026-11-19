import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/api/api_error.dart';
import 'package:leffic/shared/api/chat_api.dart';
import 'package:leffic/shared/api/chat_models.dart';

import '../../support/backend_fakes.dart';
import '../../support/property.dart';
import 'chat_fakes.dart';

void main() {
  test('ask property posts the whole conversation for the answer', () async {
    for (final (conversation, answer) in examplesOf(
      (random) => (generatedConversation(random), anyTextOf(random)),
    )) {
      final backend = FakeBackend({
        '/chat': answerWith({'answer': answer}),
      });

      final answered = await ChatApi(backend.client()).ask(conversation);
      final request = backend.received.single;

      expect(request.method, 'POST');
      expect(request.url.path, '/chat');
      expect(sentConversation(request), [
        for (final message in conversation) message.toJson(),
      ]);
      expect(answered, answer);
    }
  });

  test('ask property sends one user question and reads the answer', () async {
    for (final (question, answer) in examplesOf(
      (random) => (anyTextOf(random), anyTextOf(random)),
    )) {
      final backend = FakeBackend({
        '/chat': answerWith({'answer': answer}),
      });
      final asked = ChatMessage(role: ChatRole.user, content: question);

      final reply = await ChatApi(backend.client()).ask([asked]);
      final request = backend.received.single;

      expect(request.method, 'POST');
      expect(sentBody(request), {
        'conversation': [
          {'role': 'user', 'content': question},
        ],
      });
      expect(reply, answer);
    }
  });

  test('ask property refuses a reply without a text answer', () async {
    for (final reply in examplesOf(
      (random) => oneOf<Map<String, Object?>>(random, [
        {},
        {'answer': integerBetween(random, 0, 9)},
        {'reply': wordOf(random)},
      ]),
      runs: 10,
    )) {
      final backend = FakeBackend({'/chat': answerWith(reply)});

      await expectLater(
        ChatApi(backend.client()).ask(examplesOf(generatedMessage)),
        throwsFormatException,
      );
    }
  });

  test('ask property raises the failure the backend answers', () async {
    for (final (status, detail) in examplesOf(
      (random) => (oneOf(random, [400, 500, 503]), wordOf(random)),
      runs: 10,
    )) {
      final backend = FakeBackend({'/chat': failWith(status, detail)});

      await expectLater(
        ChatApi(backend.client()).ask(examplesOf(generatedMessage)),
        throwsA(
          isA<ApiError>()
              .having((failure) => failure.statusCode, 'statusCode', status)
              .having((failure) => failure.detail, 'detail', detail),
        ),
      );
    }
  });
}
