import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/flashcards/flashcard_faces.dart';
import 'package:leffic/features/flashcards/mnemonic_dialog.dart';
import 'package:leffic/features/flashcards/mnemonic_prompt.dart';
import 'package:leffic/shared/api/chat_api.dart';
import 'package:leffic/shared/design/design_modal.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import '../../support/property.dart';
import 'dialog_opening.dart';
import 'flashcard_generators.dart';

void main() {
  testWidgets('showMnemonicDialog property asks about the card', (
    tester,
  ) async {
    final examples = examplesOf(
      (random) => (generatedFace(random), generatedSentence(random)),
      runs: 5,
    );

    for (final (face, mnemonic) in examples) {
      final backend = FakeBackend({
        '/chat': answerWith({'answer': mnemonic}),
      });
      final chatApi = ChatApi(backend.client());
      final answers = <Object?>[];

      await tester.pumpWidget(
        openingDialog(
          (context) => showMnemonicDialog(
            context: context,
            chatApi: chatApi,
            face: face,
          ),
          answers,
        ),
      );
      await openDialog(tester);

      final asked = sentBody(backend.sentTo('/chat').single);
      final expectedQuestion = mnemonicPrompt(
        question: face.question,
        answer: face.answer,
      );

      expect(asked, {
        'conversation': [
          {'role': 'user', 'content': expectedQuestion},
        ],
      });
      final modal = tester.widget<DesignModal>(find.byType(DesignModal));

      expect(modal.title, mnemonicTitle(face.question));
      expect(modal.width, ModalWidth.wide);
      expect(find.text(mnemonic), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(answers, [null]);
    }
  });

  testWidgets('MnemonicDialog property shows a failure it can retry', (
    tester,
  ) async {
    final examples = examplesOf(
      (random) => (wordOf(random), generatedSentence(random)),
      runs: 3,
    );

    for (final (detail, mnemonic) in examples) {
      var chatReplies = 0;
      final backend = FakeBackend({
        '/chat': (request) async {
          chatReplies++;

          if (chatReplies == 1) {
            return failWith(503, detail)(request);
          }

          return jsonReply({'answer': mnemonic});
        },
      });

      await tester.pumpWidget(
        hostedPlainly(
          MnemonicDialog(
            key: UniqueKey(),
            chatApi: ChatApi(backend.client()),
            face: const BasicFace(front: 'front', back: 'back'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(detail), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text(mnemonic), findsOneWidget);
      expect(backend.sentTo('/chat').length, 2);
    }
  });
}
