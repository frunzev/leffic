import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/flashcards/flashcard_faces.dart';
import 'package:leffic/features/flashcards/flashcard_models.dart';
import 'package:leffic/features/flashcards/flashcard_session.dart';
import 'package:leffic/features/flashcards/flashcards_api.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import 'flashcard_generators.dart';

const Map<String, int> _intervals = {
  '1': 30,
  '2': 600,
  '3': 86400,
  '4': 864000,
};
const List<LogicalKeyboardKey> ratingDigitKeys = [
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
];

Flashcard _newCard(int id) {
  return Flashcard(
    id: id,
    face: BasicFace(front: 'Question $id', back: 'Answer $id'),
    nextReview: null,
    schedulingState: {'card_id': id},
  );
}

DueFlashcards dueNewCards(int count, {int extra = 0}) {
  final cards = <Flashcard>[];

  for (var id = 1; id <= count; id++) {
    cards.add(_newCard(id));
  }

  return DueFlashcards(totalCount: count + extra, cards: cards);
}

Map<String, ReplyToRequest> reviewReplies() {
  final dueLater = DateTime.now().toUtc().add(const Duration(days: 3));

  return {
    '/rating-intervals': answerWith(_intervals),
    '/review-flashcard': answerWith({
      'due_date': serverTimestamp(dueLater),
      'new_fsrs_card': {'state': 2},
    }),
    '/update-flashcard': answerWith({'msg': 'Flashcard updated!'}),
    '/delete-flashcard/': answerWith({'msg': 'Flashcard deleted!'}),
  };
}

Future<List<DueFlashcards>> pumpSession(
  WidgetTester tester, {
  required FakeBackend backend,
  required DueFlashcards firstDue,
  required List<DueFlashcards> refills,
}) async {
  final requested = <DueFlashcards>[];

  await tester.pumpWidget(
    hostedPlainly(
      FlashcardSession(
        key: UniqueKey(),
        api: FlashcardsApi(backend.client()),
        firstDue: firstDue,
        loadDue: () async {
          final refill = refills.removeAt(0);

          requested.add(refill);

          return refill;
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  return requested;
}

Future<void> openCardMenu(WidgetTester tester, String choice) async {
  await tester.tap(find.bySemanticsLabel('Actions for this card'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(choice));
  await tester.pumpAndSettle();
}
