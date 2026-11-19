import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:leffic/shared/session/backend_scope.dart';

import 'shot_backend.dart';

const int _itemsPerPage = 10;
const int _correctOptionId = 0;
const String _testSession = 'design-session';

typedef ShotQuestion = ({String question, List<String> options});
typedef ShotTest = ({
  int totalItems,
  int position,
  ShotQuestion question,
  int chosenIndex,
  int correctCount,
});

const ShotTest neuronTest = (
  totalItems: 24,
  position: 3,
  question: (
    question:
        'Which ion rushes into the neuron during the rising phase of an '
        'action potential?',
    options: ['Potassium', 'Sodium', 'Chloride', 'Calcium'],
  ),
  chosenIndex: 1,
  correctCount: 19,
);

const ShotTest homeMixedTest = (
  totalItems: 40,
  position: 7,
  question: (
    question: 'Which pump restores the resting potential after repolarisation?',
    options: ['Calcium ATPase', 'Sodium–potassium ATPase', 'Proton pump'],
  ),
  chosenIndex: 1,
  correctCount: 31,
);

const ShotTest emptyTest = (
  totalItems: 0,
  position: 1,
  question: (question: '', options: []),
  chosenIndex: 0,
  correctCount: 0,
);

List<Map<String, Object?>> _optionsJson(ShotTest test) {
  final options = <Map<String, Object?>>[];
  var wrongOptionId = _correctOptionId + 1;

  for (var index = 0; index < test.question.options.length; index++) {
    final isChosen = index == test.chosenIndex;
    final optionId = isChosen ? _correctOptionId : wrongOptionId++;

    options.add({'id': optionId, 'option': test.question.options[index]});
  }

  return options;
}

Map<String, Object?> _shownItemJson(ShotTest test) {
  return {
    'id': test.position,
    'type': 'multiple_choice',
    'content': {
      'question': test.question.question,
      'shuffled_options': _optionsJson(test),
    },
    'last_answers': [_correctOptionId],
  };
}

Map<String, Object?> _fillerItemJson(int number) {
  return {
    'id': number,
    'type': 'multiple_choice',
    'content': {
      'question': 'Question $number?',
      'shuffled_options': [
        {'id': 0, 'option': 'Right $number'},
        {'id': 1, 'option': 'Wrong $number'},
      ],
    },
    'last_answers': null,
  };
}

Map<String, Object?> _pageJson(ShotTest test, int pageNumber) {
  final firstNumber = (pageNumber - 1) * _itemsPerPage + 1;
  final lastNumber = min(test.totalItems, pageNumber * _itemsPerPage);
  final items = <Map<String, Object?>>[];

  for (var number = firstNumber; number <= lastNumber; number++) {
    final isShown = number == test.position;

    items.add(isShown ? _shownItemJson(test) : _fillerItemJson(number));
  }

  return {
    'test_items': items,
    'total_items': test.totalItems,
    'test_session': _testSession,
    'page': pageNumber,
    'per_page': _itemsPerPage,
  };
}

List<int> _missedItemIds(ShotTest test) {
  final missedCount = test.totalItems - test.correctCount;

  return List.generate(missedCount, (index) => index + 1);
}

class AssessmentShotBackend {
  const AssessmentShotBackend(this.test);

  final ShotTest test;

  Future<http.Response> answer(http.Request request) async {
    return switch (request.url.path) {
      '/test-items' => shotJsonReply(
        _pageJson(test, int.parse(request.url.queryParameters['page']!)),
      ),
      '/review-test-item' => shotJsonReply({'msg': 'Saved!'}),
      '/test-session-results' => shotJsonReply({
        'correct': test.correctCount,
        'missed_item_ids': _missedItemIds(test),
      }),
      _ => shotNotFoundReply(),
    };
  }

  BackendLink link() {
    return shotBackendLink(answer);
  }
}
