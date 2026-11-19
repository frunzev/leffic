import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/chat/chat_failure.dart';
import 'package:leffic/shared/api/api_error.dart';

import '../../support/property.dart';

void main() {
  test('chatFailureMessage property explains only an unavailable chat', () {
    forAll(
      (random) => (
        oneOf(random, [503, integerBetween(random, 400, 599)]),
        'Claude Code did not answer ${wordOf(random)}',
      ),
      (example) {
        final (status, detail) = example;
        final failure = ApiError(
          statusCode: status,
          path: '/chat',
          detail: detail,
        );
        final message = chatFailureMessage(failure);

        expect(message, status == 503 ? detail : genericChatFailure);
      },
    );
  });

  test('chatFailureMessage property hides failures from elsewhere', () {
    forAll(
      (random) => oneOf<Exception>(random, [
        FormatException(wordOf(random)),
        HttpException(wordOf(random)),
        FileSystemException(wordOf(random)),
      ]),
      (failure) {
        expect(chatFailureMessage(failure), genericChatFailure);
      },
    );
  });
}
