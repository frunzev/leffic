import '../../shared/api/api_client.dart';
import '../../shared/api/json_reading.dart';
import 'flashcard_faces.dart';
import 'flashcard_models.dart';

typedef DueFlashcardsLoader = Future<DueFlashcards> Function();

class FlashcardsApi {
  const FlashcardsApi(this.client);

  final ApiClient client;

  Future<DueFlashcards> deckFlashcards(String deckId) {
    return _dueFlashcards({'flashcard_deck_id': deckId});
  }

  Future<DueFlashcards> folderFlashcards(String folderId) {
    return _dueFlashcards({'folder_id': folderId});
  }

  Future<RatingIntervals> ratingIntervals(JsonObject? schedulingState) async {
    final reply = await client.sendJson('POST', '/rating-intervals', {
      'card': schedulingState,
    });

    return RatingIntervals.fromJson(asObject(reply));
  }

  Future<ReviewOutcome> review({
    required int flashcardId,
    required FlashcardRating rating,
  }) async {
    final reply = await client.sendJson('POST', '/review-flashcard', {
      'flashcard_id': flashcardId,
      'rating': rating.score,
    });

    return ReviewOutcome.fromJson(asObject(reply));
  }

  Future<void> updateFace({
    required int flashcardId,
    required FlashcardFace face,
  }) async {
    await client.sendJson('PATCH', '/update-flashcard', {
      'flashcard_id': flashcardId,
      'content': face.toContent(),
    });
  }

  Future<void> delete(int flashcardId) async {
    await client.delete('/delete-flashcard/', {'flashcard_id': '$flashcardId'});
  }

  Future<DueFlashcards> _dueFlashcards(QueryParameters scope) async {
    final reply = await client.getJson('/flashcards', scope);

    return DueFlashcards.fromJson(asObject(reply));
  }
}
