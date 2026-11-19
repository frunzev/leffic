import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leffic/features/flashcards/deck_review_page.dart';
import 'package:leffic/features/flashcards/folder_review_page.dart';
import 'package:leffic/shared/navigation/routes.dart';
import 'package:leffic/shared/session/backend_scope.dart';
import 'package:leffic/shared/widgets/ask_panel_scope.dart';

import 'shot_backend.dart';
import 'shot_support.dart';

const String _deckQuestion =
    'What is the resting membrane potential of a typical neuron?';
const String _deckAnswer =
    'About −70 mV, held by the sodium–potassium pump and potassium leak '
    'channels.';
const String _shortAnswer = 'About −70 mV.';
const String _mixedQuestion =
    'Which ion channel opens first during depolarisation?';
const Map<String, int> _designIntervals = {
  '1': 60,
  '2': 480,
  '3': 259200,
  '4': 1036800,
};
const Map<String, Object?> _farReview = {
  'due_date': '2099-01-01 00:00:00',
  'new_fsrs_card': {'state': 2},
};

typedef _CardContent = Map<String, Object?>;
typedef _ReviewedDeck = ({
  int reviewedCount,
  int totalCount,
  String type,
  _CardContent content,
});

const _ReviewedDeck _actionPotentialsDeck = (
  reviewedCount: 8,
  totalCount: 30,
  type: 'basic',
  content: {'front': _deckQuestion, 'back': _deckAnswer},
);
const _ReviewedDeck _shortAnswerDeck = (
  reviewedCount: 8,
  totalCount: 30,
  type: 'basic',
  content: {'front': _deckQuestion, 'back': _shortAnswer},
);
const _ReviewedDeck _emptyDeck = (
  reviewedCount: 0,
  totalCount: 0,
  type: 'basic',
  content: {},
);
const _ReviewedDeck _homeFolder = (
  reviewedCount: 21,
  totalCount: 50,
  type: 'basic',
  content: {'front': _mixedQuestion, 'back': _deckAnswer},
);
const _ReviewedDeck _clozeDeck = (
  reviewedCount: 3,
  totalCount: 12,
  type: 'cloze',
  content: {
    'text': 'A typical neuron rests at about −70 mV, held by the pump.',
    'hidden_parts': ['−70 mV', 'pump'],
  },
);
const _ReviewedDeck _listDeck = (
  reviewedCount: 3,
  totalCount: 12,
  type: 'list',
  content: {
    'question': 'Which ions set the resting membrane potential?',
    'items': ['Potassium leaking out', 'Sodium kept outside', 'Chloride'],
  },
);

Map<String, Object?> _cardJson(int id, String type, _CardContent content) {
  return {
    'id': id,
    'type': type,
    'next_review': null,
    'content': content,
    'created_at': '2026-11-01 08:00:00',
    'fsrs_card': null,
  };
}

Map<String, Object?> _dueJson(_ReviewedDeck deck) {
  final cards = <Map<String, Object?>>[];

  for (var id = 1; id <= deck.reviewedCount; id++) {
    final earlierContent = {'front': 'Card $id', 'back': 'Answer $id'};

    cards.add(_cardJson(id, 'basic', earlierContent));
  }

  if (deck.totalCount > 0) {
    cards.add(_cardJson(deck.reviewedCount + 1, deck.type, deck.content));
  }

  return {'flashcards': cards, 'total_flashcards': deck.totalCount};
}

class _DeckReplies {
  const _DeckReplies(this.deck);

  final _ReviewedDeck deck;

  Future<http.Response> answer(http.Request request) async {
    return switch (request.url.path) {
      '/flashcards' => shotJsonReply(_dueJson(deck)),
      '/rating-intervals' => shotJsonReply(_designIntervals),
      '/review-flashcard' => shotJsonReply(_farReview),
      _ => shotNotFoundReply(),
    };
  }
}

Widget _deckPage(_ReviewedDeck deck) {
  return BackendScope(
    link: shotBackendLink(_DeckReplies(deck).answer),
    child: const DeckReviewPage(arguments: UnitArguments(id: 'deck')),
  );
}

Widget _mixedPage(_ReviewedDeck deck) {
  return BackendScope(
    link: shotBackendLink(_DeckReplies(deck).answer),
    child: const FolderReviewPage(
      arguments: UnitArguments(id: homeFolderId, name: 'Home'),
    ),
  );
}

Future<void> _pumpReview(
  WidgetTester tester,
  Brightness brightness,
  Widget page,
  _ReviewedDeck deck,
) async {
  await pumpShotApp(
    tester,
    brightness: brightness,
    askPanel: AskPanelController(),
    panel: surfacePanelFor(brightness),
    home: page,
  );
  await tester.pumpAndSettle();

  for (var reviewed = 0; reviewed < deck.reviewedCount; reviewed++) {
    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Easy'));
    await tester.pumpAndSettle();
  }
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('flashcards question in ${brightness.name}', (tester) async {
      const deck = _actionPotentialsDeck;

      await _pumpReview(tester, brightness, _deckPage(deck), deck);
      await saveShot(tester, 'flashcards-question', brightness);
      releaseDesktopWindow();
    });

    testWidgets('flashcards answer in ${brightness.name}', (tester) async {
      const deck = _actionPotentialsDeck;

      await _pumpReview(tester, brightness, _deckPage(deck), deck);
      await tester.tap(find.text('Show answer'));
      await tester.pumpAndSettle();
      await saveShot(tester, 'flashcards-answer', brightness);
      releaseDesktopWindow();
    });

    testWidgets('flashcards menu in ${brightness.name}', (tester) async {
      const deck = _actionPotentialsDeck;

      await _pumpReview(tester, brightness, _deckPage(deck), deck);
      await openDotsMenu(tester);
      await saveShot(tester, 'flashcards-menu', brightness);
      releaseDesktopWindow();
    });

    testWidgets('flashcard edit in ${brightness.name}', (tester) async {
      const deck = _shortAnswerDeck;

      await _pumpReview(tester, brightness, _deckPage(deck), deck);
      await openDotsMenu(tester);
      await tester.tap(find.text('Edit card'));
      await tester.pumpAndSettle();
      await saveShot(tester, 'flashcard-edit', brightness);
      releaseDesktopWindow();
    });

    testWidgets('flashcard delete in ${brightness.name}', (tester) async {
      const deck = _actionPotentialsDeck;

      await _pumpReview(tester, brightness, _deckPage(deck), deck);
      await openDotsMenu(tester);
      await tester.tap(find.text('Delete card'));
      await tester.pumpAndSettle();
      await saveShot(tester, 'flashcard-delete', brightness);
      releaseDesktopWindow();
    });

    testWidgets('flashcards empty in ${brightness.name}', (tester) async {
      const deck = _emptyDeck;

      await _pumpReview(tester, brightness, _deckPage(deck), deck);
      await saveShot(tester, 'flashcards-empty', brightness);
      releaseDesktopWindow();
    });

    for (final (name, deck) in [
      ('flashcards-cloze', _clozeDeck),
      ('flashcards-list', _listDeck),
    ]) {
      testWidgets('$name in ${brightness.name}', (tester) async {
        await _pumpReview(tester, brightness, _deckPage(deck), deck);
        await tester.tap(find.text('Show answer'));
        await tester.pumpAndSettle();
        await saveShot(tester, name, brightness);
        releaseDesktopWindow();
      });
    }

    testWidgets('flashcards mixed in ${brightness.name}', (tester) async {
      const deck = _homeFolder;

      await _pumpReview(tester, brightness, _mixedPage(deck), deck);
      await saveShot(tester, 'flashcards-mixed', brightness);
      releaseDesktopWindow();
    });
  }
}
