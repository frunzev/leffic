import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/flashcards/flashcard_models.dart';
import 'package:leffic/features/flashcards/flashcards_api.dart';
import 'package:leffic/shared/api/api_error.dart';

import '../../support/backend_fakes.dart';
import '../../support/property.dart';
import 'flashcard_generators.dart';

void main() {
  test('deckFlashcards property asks for the due cards of the deck', () async {
    for (final (deckId, dueJson) in examplesOf(
      (random) => (tokenOf(random), generatedDueJson(random)),
    )) {
      final backend = FakeBackend({'/flashcards': answerWith(dueJson)});

      final due = await FlashcardsApi(backend.client()).deckFlashcards(deckId);
      final request = backend.received.single;

      expect(request.method, 'GET');
      expect(request.url.queryParameters, {'flashcard_deck_id': deckId});
      expect(due.totalCount, dueJson['total_flashcards']);
      expect(due.cards.length, (dueJson['flashcards']! as List).length);
    }
  });

  test(
    'folderFlashcards property asks for the due cards of the folder',
    () async {
      for (final (folderId, dueJson) in examplesOf(
        (random) => (
          oneOf(random, ['home', tokenOf(random)]),
          generatedDueJson(random),
        ),
      )) {
        final backend = FakeBackend({'/flashcards': answerWith(dueJson)});

        final due = await FlashcardsApi(backend.client())
            .folderFlashcards(folderId);
        final request = backend.received.single;

        expect(request.method, 'GET');
        expect(request.url.queryParameters, {'folder_id': folderId});
        expect(due.totalCount, dueJson['total_flashcards']);
      }
    },
  );

  test('ratingIntervals property posts the scheduling state', () async {
    for (final (state, intervalsJson) in examplesOf(
      (random) => (
        random.nextBool() ? null : generatedSchedulingState(random),
        generatedIntervalsJson(random),
      ),
    )) {
      final backend = FakeBackend({
        '/rating-intervals': answerWith(intervalsJson),
      });

      final intervals = await FlashcardsApi(backend.client())
          .ratingIntervals(state);
      final request = backend.received.single;

      expect(request.method, 'POST');
      expect(sentBody(request), {'card': state});
      expect(intervals.secondsFor(FlashcardRating.good), intervalsJson['3']);
    }
  });

  test('review property posts the card id and the rating score', () async {
    for (final (flashcardId, rating, dueDate) in examplesOf(
      (random) => (
        integerBetween(random, 1, 99999),
        oneOf(random, FlashcardRating.values),
        generatedUtcMoment(random),
      ),
    )) {
      final backend = FakeBackend({
        '/review-flashcard': answerWith({
          'due_date': serverTimestamp(dueDate),
          'new_fsrs_card': {'state': 2},
        }),
      });

      final outcome = await FlashcardsApi(backend.client())
          .review(flashcardId: flashcardId, rating: rating);
      final request = backend.received.single;

      expect(request.method, 'POST');
      expect(sentBody(request), {
        'flashcard_id': flashcardId,
        'rating': rating.score,
      });
      expect(outcome.dueDate, dueDate);
      expect(outcome.schedulingState, {'state': 2});
    }
  });

  test('updateFace property patches the id and the face content', () async {
    for (final (flashcardId, face) in examplesOf(
      (random) => (integerBetween(random, 1, 99999), generatedFace(random)),
    )) {
      final backend = FakeBackend({
        '/update-flashcard': answerWith({'msg': 'Flashcard updated!'}),
      });

      await FlashcardsApi(backend.client())
          .updateFace(flashcardId: flashcardId, face: face);
      final request = backend.received.single;

      expect(request.method, 'PATCH');
      expect(sentBody(request), {
        'flashcard_id': flashcardId,
        'content': face.toContent(),
      });
    }
  });

  test('delete property deletes the card by its id', () async {
    for (final flashcardId in examplesOf(
      (random) => integerBetween(random, 1, 99999),
    )) {
      final backend = FakeBackend({
        '/delete-flashcard/': answerWith({'msg': 'Flashcard deleted!'}),
      });

      await FlashcardsApi(backend.client()).delete(flashcardId);
      final request = backend.received.single;

      expect(request.method, 'DELETE');
      expect(request.url.queryParameters, {'flashcard_id': '$flashcardId'});
    }
  });

  test('FlashcardsApi property raises every failure', () async {
    for (final status in examplesOf(
      (random) => oneOf(random, [400, 401, 404, 422, 500, 503]),
      runs: 10,
    )) {
      final api = FlashcardsApi(
        FakeBackend({
          '/flashcards': failWith(status, 'refused'),
          '/review-flashcard': failWith(status, 'refused'),
        }).client(),
      );

      await expectLater(api.deckFlashcards('deck'), throwsA(isA<ApiError>()));
      await expectLater(
        api.review(flashcardId: 1, rating: FlashcardRating.again),
        throwsA(isA<ApiError>()),
      );
    }
  });
}
