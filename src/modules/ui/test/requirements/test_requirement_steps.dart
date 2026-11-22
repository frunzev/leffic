import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leffic/features/assessment/test_page.dart';
import 'package:leffic/shared/navigation/routes.dart';

import '../features/assessment/temporary_support_directory.dart';
import '../support/backend_fakes.dart';
import '../support/hosting.dart';
import 'requirement_world.dart';
import 'step_definition.dart';

const String _testItems = '/test-items';
const String _reviewTestItem = '/review-test-item';
const String _sessionResults = '/test-session-results';
const String _finish = 'Finish';
const String _testSession = 'requirement-session';
const int _questionId = 1;
const int _rightOptionId = 0;
const int _wrongOptionId = 1;

class _ScoredTest {
  _ScoredTest(this.backend);

  final FakeBackend Function() backend;

  Future<http.Response> results(http.Request request) async {
    final answers = <Object?>[];

    for (final review in backend().sentTo(_reviewTestItem)) {
      answers.add(sentBody(review)['answers']);
    }

    final isRight = answers.length == 1 && answers.single.toString() == '[0]';

    return jsonReply({
      'correct': isRight ? 1 : 0,
      'missed_item_ids': isRight ? <int>[] : [_questionId],
    });
  }
}

Map<String, Object?> _testPage(String question, List<String> options) {
  final [rightOption, wrongOption] = options;

  return {
    'test_items': [
      {
        'id': _questionId,
        'type': 'multiple_choice',
        'content': {
          'question': question,
          'shuffled_options': [
            {'id': _wrongOptionId, 'option': wrongOption},
            {'id': _rightOptionId, 'option': rightOption},
          ],
        },
        'last_answers': null,
      },
    ],
    'total_items': 1,
    'test_session': _testSession,
    'page': 1,
    'per_page': 10,
  };
}

Future<void> _serveTest(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final [_, question, rightOption, wrongOption] = values;

  world.optionIds[rightOption] = _rightOptionId;
  world.optionIds[wrongOption] = _wrongOptionId;
  world.replies[_testItems] = answerWith(
    _testPage(question, [rightOption, wrongOption]),
  );
  world.replies[_reviewTestItem] = answerWith({'msg': 'Saved!'});
  world.replies[_sessionResults] = _ScoredTest(world.backend).results;
}

Future<void> _takeTest(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final [testName, chosenOption] = values;
  final arguments = UnitArguments(id: 'test-$testName', name: testName);

  useTemporarySupportDirectory();
  await pumpOnTopOfFolder(
    tester,
    client: world.client(),
    page: TestPage(arguments: arguments),
  );
  await tester.tap(find.text(chosenOption));
  await tester.pump();
  await tester.tap(find.text(_finish));
  await tester.pumpAndSettle();
}

Future<void> _checkSentAnswer(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final review = world.backend().sentTo(_reviewTestItem).single;
  final sentAnswer = sentBody(review);

  expect(sentAnswer['test_item_id'], _questionId);
  expect(sentAnswer['answers'], [world.optionIds[values.single]]);
}

final List<StepDefinition> testStepDefinitions = [
  StepDefinition(
    'Given',
    RegExp(
      r'^the backend has the test "(.+)" asking "(.+)" '
      r'with "(.+)" right and "(.+)" wrong$',
    ),
    _serveTest,
  ),
  StepDefinition(
    'When',
    RegExp(r'^I take the test "(.+)" in the app choosing "(.+)"$'),
    _takeTest,
  ),
  StepDefinition(
    'Then',
    RegExp(r'^the backend received my answer "(.+)"$'),
    _checkSentAnswer,
  ),
];
