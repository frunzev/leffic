import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leffic/features/flashcards/deck_review_page.dart';
import 'package:leffic/features/flashcards/rating_button.dart';
import 'package:leffic/shared/navigation/routes.dart';

import '../support/backend_fakes.dart';
import '../support/hosting.dart';
import 'requirement_world.dart';
import 'step_definition.dart';

const String _flashcards = '/flashcards';
const String _ratingIntervals = '/rating-intervals';
const String _reviewFlashcard = '/review-flashcard';
const String _showAnswer = 'Show answer';
const int _missingStatus = 404;
const Map<String, Object?> _nothingDue = {
  'flashcards': <Object?>[],
  'total_flashcards': 0,
};
const Map<String, Object?> _scheduledReview = {
  'due_date': '2099-01-01 00:00:00',
  'new_fsrs_card': {'state': 2},
};

class _OneDueCard {
  _OneDueCard(this.front, this.back);

  final String front;
  final String back;
  var _isAnswered = false;

  Future<http.Response> reply(http.Request request) async {
    if (_isAnswered) {
      return jsonReply(_nothingDue);
    }

    _isAnswered = true;

    return jsonReply({
      'flashcards': [
        {
          'id': 41,
          'type': 'basic',
          'next_review': null,
          'content': {'front': front, 'back': back},
          'created_at': '2026-11-01 08:00:00',
          'fsrs_card': null,
        },
      ],
      'total_flashcards': 1,
    });
  }
}

Future<void> _serveDeck(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final [_, front, back] = values;

  world.replies[_flashcards] = _OneDueCard(front, back).reply;
  world.replies[_ratingIntervals] = (request) async {
    return jsonReply(world.intervalSeconds);
  };
  world.replies[_reviewFlashcard] = answerWith(_scheduledReview);
}

Future<void> _setInterval(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final [seconds, rating] = values;

  world.intervalSeconds[ratingScores[rating]!] = int.parse(seconds);
}

Future<void> _refuseDeck(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final [_, refusal] = values;

  world.replies[_flashcards] = failWith(_missingStatus, refusal);
}

Future<void> _reviewDeck(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final deckName = values.single;
  final arguments = UnitArguments(id: 'deck-$deckName', name: deckName);

  await pumpOnTopOfFolder(
    tester,
    client: world.client(),
    page: DeckReviewPage(arguments: arguments),
  );
}

Future<void> _tapText(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  await tester.tap(find.text(values.single));
  await tester.pumpAndSettle();
}

Future<void> _showAnswerOf(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  await _tapText(tester, world, [_showAnswer]);
}

Future<void> _checkButtonInterval(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final [rating, intervalText] = values;
  final buttons = tester.widgetList<RatingButton>(find.byType(RatingButton));
  final shownIntervals = <String, String>{};

  for (final button in buttons) {
    shownIntervals[button.rating.label] = button.intervalText;
  }

  expect(shownIntervals[rating], intervalText);
}

Future<void> _checkSentRating(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final ratingRequest = world.backend().sentTo(_reviewFlashcard).single;

  expect(sentBody(ratingRequest)['rating'], int.parse(values.single));
}

final List<StepDefinition> reviewStepDefinitions = [
  StepDefinition(
    'Given',
    RegExp(
      r'^the backend has the deck "(.+)" '
      r'with the due card "(.+)" answered "(.+)"$',
    ),
    _serveDeck,
  ),
  StepDefinition(
    'Given',
    RegExp(r'^the backend brings the card back in (\d+) seconds for "(.+)"$'),
    _setInterval,
  ),
  StepDefinition(
    'Given',
    RegExp(r'^the backend refuses the deck "(.+)" with "(.+)"$'),
    _refuseDeck,
  ),
  StepDefinition(
    'When',
    RegExp(r'^I review the deck "(.+)" in the app$'),
    _reviewDeck,
  ),
  StepDefinition('When', RegExp(r'^I show the answer$'), _showAnswerOf),
  StepDefinition('When', RegExp(r'^I rate the card "(.+)"$'), _tapText),
  StepDefinition(
    'Then',
    RegExp(r'^the "(.+)" button says "(.+)"$'),
    _checkButtonInterval,
  ),
  StepDefinition(
    'Then',
    RegExp(r'^the backend received the rating (\d+)$'),
    _checkSentRating,
  ),
];
