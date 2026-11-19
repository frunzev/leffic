import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/assessment/assessment_api.dart';
import 'package:leffic/features/assessment/edited_test_item.dart';
import 'package:leffic/features/assessment/test_answer.dart';
import 'package:leffic/shared/api/api_error.dart';

import '../../support/backend_fakes.dart';
import '../../support/property.dart';
import 'assessment_generators.dart';

void main() {
  test('testItemsPage property asks for one page of the test', () async {
    for (final (testId, pageNumber, pageJson) in examplesOf(
      (random) => (
        tokenOf(random),
        integerBetween(random, 1, 9),
        generatedPageJson(random),
      ),
    )) {
      final backend = FakeBackend({'/test-items': answerWith(pageJson)});

      final page = await AssessmentApi(backend.client())
          .testItemsPage(testId: testId, pageNumber: pageNumber);
      final request = backend.received.single;

      expect(request.method, 'GET');
      expect(request.url.queryParameters, {
        'test_id': testId,
        'page': '$pageNumber',
        'per_page': '10',
      });
      expect(page.testSession, pageJson['test_session']);
    }
  });

  test('folderItemsPage property asks for one page of the folder', () async {
    for (final (folderId, pageNumber, pageJson) in examplesOf(
      (random) => (
        oneOf(random, ['home', tokenOf(random)]),
        integerBetween(random, 1, 9),
        generatedPageJson(random),
      ),
    )) {
      final backend = FakeBackend({'/test-items': answerWith(pageJson)});

      final page = await AssessmentApi(backend.client())
          .folderItemsPage(folderId: folderId, pageNumber: pageNumber);
      final request = backend.received.single;

      expect(request.method, 'GET');
      expect(request.url.queryParameters, {
        'folder_id': folderId,
        'page': '$pageNumber',
        'per_page': '10',
      });
      expect(page.totalItems, pageJson['total_items']);
    }
  });

  test('submitAnswers property posts the item, session and answers', () async {
    for (final (testItemId, testSession, wireValue) in examplesOf(
      (random) => (
        integerBetween(random, 1, 99999),
        tokenOf(random),
        oneOf<Object>(random, [integerBetween(random, 0, 4), wordOf(random)]),
      ),
    )) {
      final backend = FakeBackend({
        '/review-test-item': answerWith({'msg': 'Saved!'}),
      });

      await AssessmentApi(backend.client()).submitAnswers(
        testItemId: testItemId,
        testSession: testSession,
        answers: [TestAnswer.fromWire(wireValue)],
      );
      final request = backend.received.single;

      expect(request.method, 'POST');
      expect(sentBody(request), {
        'test_item_id': testItemId,
        'test_session': testSession,
        'answers': [wireValue],
      });
    }
  });

  test('missedTestItemsPage property asks for the missed of a test', () async {
    for (final (testId, finishedSession, pageNumber, pageJson) in examplesOf(
      (random) => (
        tokenOf(random),
        tokenOf(random),
        integerBetween(random, 1, 9),
        generatedPageJson(random),
      ),
    )) {
      final backend = FakeBackend({'/test-items': answerWith(pageJson)});

      final page = await AssessmentApi(backend.client()).missedTestItemsPage(
        testId: testId,
        finishedSession: finishedSession,
        pageNumber: pageNumber,
      );
      final request = backend.received.single;

      expect(request.method, 'GET');
      expect(request.url.queryParameters, {
        'test_id': testId,
        'missed_in_session': finishedSession,
        'page': '$pageNumber',
        'per_page': '10',
      });
      expect(page.testSession, pageJson['test_session']);
    }
  });

  test(
    'missedFolderItemsPage property asks for the missed of a folder',
    () async {
      for (final (folderId, finishedSession, pageNumber, pageJson)
          in examplesOf(
            (random) => (
              oneOf(random, ['home', tokenOf(random)]),
              tokenOf(random),
              integerBetween(random, 1, 9),
              generatedPageJson(random),
            ),
          )) {
        final backend = FakeBackend({'/test-items': answerWith(pageJson)});

        final page = await AssessmentApi(backend.client())
            .missedFolderItemsPage(
              folderId: folderId,
              finishedSession: finishedSession,
              pageNumber: pageNumber,
            );
        final request = backend.received.single;

        expect(request.url.queryParameters, {
          'folder_id': folderId,
          'missed_in_session': finishedSession,
          'page': '$pageNumber',
          'per_page': '10',
        });
        expect(page.totalItems, pageJson['total_items']);
      }
    },
  );

  test('sessionResult property reads the score and the missed ids', () async {
    for (final (testSession, correct, missedItemIds) in examplesOf(
      (random) => (
        tokenOf(random),
        integerBetween(random, 0, 60),
        List.generate(
          integerBetween(random, 0, 6),
          (index) => integerBetween(random, 1, 9999),
        ),
      ),
    )) {
      final backend = FakeBackend({
        '/test-session-results': answerWith({
          'correct': correct,
          'missed_item_ids': missedItemIds,
        }),
      });

      final result = await AssessmentApi(backend.client())
          .sessionResult(testSession);
      final request = backend.received.single;

      expect(request.method, 'GET');
      expect(request.url.queryParameters, {'test_session': testSession});
      expect(result.correctCount, correct);
      expect(result.missedItemIds, missedItemIds);
    }
  });

  test(
    'sessionResult property scores nothing when nothing was answered',
    () async {
      for (final testSession in examplesOf(tokenOf, runs: 10)) {
        final backend = FakeBackend({
          '/test-session-results': failWith(404, 'No test stats!'),
        });

        final result = await AssessmentApi(backend.client())
            .sessionResult(testSession);

        expect(result.correctCount, 0);
        expect(result.missedItemIds, isEmpty);
      }
    },
  );

  test('sessionResult property raises other failures', () async {
    for (final status in examplesOf(
      (random) => oneOf(random, [400, 401, 422, 500, 503]),
      runs: 10,
    )) {
      final backend = FakeBackend({
        '/test-session-results': failWith(status, 'refused'),
      });

      await expectLater(
        AssessmentApi(backend.client()).sessionResult('session'),
        throwsA(isA<ApiError>()),
      );
    }
  });

  test(
    'updateItem property patches the item with the edited content',
    () async {
      for (final (testItemId, question, answers) in examplesOf(
        (random) => (
          integerBetween(random, 1, 99999),
          generatedQuestion(random),
          [wordOf(random), wordOf(random), wordOf(random)],
        ),
      )) {
        final backend = FakeBackend({
          '/update-test-item': answerWith({'msg': 'Test item updated!'}),
        });
        final edited = EditedTestItem.fromAnswers(
          question: question,
          answers: answers,
          correctIndex: 1,
        );

        await AssessmentApi(backend.client())
            .updateItem(testItemId: testItemId, edited: edited);
        final request = backend.received.single;

        expect(request.method, 'PATCH');
        expect(sentBody(request), {
          'test_item_id': testItemId,
          'content': edited.toContent(),
        });
      }
    },
  );
}
