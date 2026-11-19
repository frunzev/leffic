import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/flashcards/flashcard_models.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import '../../support/property.dart';
import 'flashcard_session_harness.dart';

void main() {
  testWidgets('FlashcardSession property reveals the answer and intervals', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final count in examplesOf(
      (random) => integerBetween(random, 1, 5),
      runs: 4,
    )) {
      final backend = FakeBackend(reviewReplies());

      await pumpSession(
        tester,
        backend: backend,
        firstDue: dueNewCards(count),
        refills: [],
      );

      expect(find.text('Question 1'), findsOneWidget);
      expect(find.text('Answer 1'), findsNothing);

      await tester.tap(find.text('Show answer'));
      await tester.pumpAndSettle();

      expect(find.text('Answer 1'), findsOneWidget);
      expect(find.text('1 days'), findsOneWidget);
      expect(sentBody(backend.sentTo('/rating-intervals').single), {
        'card': {'card_id': 1},
      });
    }
  });

  testWidgets('FlashcardSession property rates and moves to the next card', (
    tester,
  ) async {
    useDesktopSurface(tester);

    final examples = examplesOf(
      (random) =>
          (integerBetween(random, 2, 5), oneOf(random, FlashcardRating.values)),
      runs: 4,
    );

    for (final (count, rating) in examples) {
      final backend = FakeBackend(reviewReplies());

      await pumpSession(
        tester,
        backend: backend,
        firstDue: dueNewCards(count),
        refills: [],
      );

      for (var reviewed = 1; reviewed < count; reviewed++) {
        await tester.tap(find.text('Show answer'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(rating.label));
        await tester.pumpAndSettle();

        expect(find.text('Question ${reviewed + 1}'), findsOneWidget);
        expect(find.text('Reviewed $reviewed of $count'), findsOneWidget);
      }

      final sentRatings = backend.sentTo('/review-flashcard');

      expect(sentRatings.length, count - 1);
      expect(sentBody(sentRatings.first), {
        'flashcard_id': 1,
        'rating': rating.score,
      });
    }
  });

  testWidgets('FlashcardSession property follows the keyboard shortcuts', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final rating in FlashcardRating.values) {
      final backend = FakeBackend(reviewReplies());

      await pumpSession(
        tester,
        backend: backend,
        firstDue: dueNewCards(2),
        refills: [],
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1, character: '1');
      await tester.pumpAndSettle();

      expect(backend.sentTo('/review-flashcard'), isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(find.text('Answer 1'), findsOneWidget);

      await tester.sendKeyEvent(
        ratingDigitKeys[rating.index],
        character: '${rating.score}',
      );
      await tester.pumpAndSettle();

      expect(sentBody(backend.sentTo('/review-flashcard').single), {
        'flashcard_id': 1,
        'rating': rating.score,
      });
      expect(find.text('Question 2'), findsOneWidget);
    }
  });

  testWidgets('FlashcardSession property refills, then finishes the day', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final extra in examplesOf(
      (random) => integerBetween(random, 0, 9),
      runs: 3,
    )) {
      final backend = FakeBackend(reviewReplies());
      final requested = await pumpSession(
        tester,
        backend: backend,
        firstDue: dueNewCards(1, extra: extra),
        refills: [dueNewCards(1), dueNewCards(0)],
      );

      for (var round = 0; round < 2; round++) {
        await tester.tap(find.text('Show answer'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Good'));
        await tester.pumpAndSettle();
      }

      expect(requested.length, 2);
      expect(find.text("You're done for today"), findsOneWidget);
    }
  });

  testWidgets('FlashcardSession property finishes at once with no cards', (
    tester,
  ) async {
    useDesktopSurface(tester);

    await pumpSession(
      tester,
      backend: FakeBackend(reviewReplies()),
      firstDue: dueNewCards(0),
      refills: [],
    );

    expect(find.text("You're done for today"), findsOneWidget);
    expect(find.text('Show answer'), findsNothing);
  });
}
