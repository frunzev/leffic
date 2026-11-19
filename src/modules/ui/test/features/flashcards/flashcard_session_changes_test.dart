import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_field.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';
import 'flashcard_generators.dart';
import 'flashcard_session_harness.dart';

void main() {
  testWidgets('FlashcardSession property deletes a confirmed card', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final count in examplesOf(
      (random) => integerBetween(random, 2, 6),
      runs: 3,
    )) {
      final backend = FakeBackend(reviewReplies());

      await pumpSession(
        tester,
        backend: backend,
        firstDue: dueNewCards(count),
        refills: [],
      );
      await openCardMenu(tester, 'Delete card');
      await tester.tap(find.text('Delete card'));
      await tester.pumpAndSettle();

      final deletion = backend.sentTo('/delete-flashcard/').single;

      expect(deletion.url.queryParameters, {'flashcard_id': '1'});
      expect(find.text('Question 2'), findsOneWidget);
      expect(find.text('Reviewed 0 of ${count - 1}'), findsOneWidget);
    }
  });

  testWidgets('FlashcardSession property saves an edited card', (tester) async {
    useDesktopSurface(tester);

    for (final front in examplesOf(generatedSentence, runs: 3)) {
      final backend = FakeBackend(reviewReplies());

      await pumpSession(
        tester,
        backend: backend,
        firstDue: dueNewCards(2),
        refills: [],
      );
      await openCardMenu(tester, 'Edit card');
      await tester.enterText(
        find.descendant(
          of: find.widgetWithText(DesignField, 'Front'),
          matching: find.byType(TextField),
        ),
        front,
      );
      await tester.pump();
      await tester.tap(find.text('Save card'));
      await tester.pumpAndSettle();

      expect(sentBody(backend.sentTo('/update-flashcard').single), {
        'flashcard_id': 1,
        'content': {'front': front, 'back': 'Answer 1'},
      });
      expect(findShownText(front), findsOneWidget);
    }
  });

  testWidgets('FlashcardSession property reports a failed review', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final detail in examplesOf(wordOf, runs: 3)) {
      final backend = FakeBackend({
        ...reviewReplies(),
        '/review-flashcard': failWith(500, detail),
      });

      await pumpSession(
        tester,
        backend: backend,
        firstDue: dueNewCards(2),
        refills: [],
      );
      await tester.tap(find.text('Show answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Again'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't save your rating"), findsOneWidget);
      expect(find.text(detail), findsOneWidget);
      expect(find.text('Question 1'), findsOneWidget);
      expect(find.text('Show answer'), findsOneWidget);
    }
  });

  testWidgets('FlashcardSession property reports failed card changes', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final detail in examplesOf(wordOf, runs: 2)) {
      final backend = FakeBackend({
        ...reviewReplies(),
        '/update-flashcard': failWith(500, detail),
        '/delete-flashcard/': failWith(500, detail),
      });

      await pumpSession(
        tester,
        backend: backend,
        firstDue: dueNewCards(2),
        refills: [],
      );
      await openCardMenu(tester, 'Edit card');
      await tester.tap(find.text('Save card'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't save the card"), findsOneWidget);

      await openCardMenu(tester, 'Delete card');
      await tester.tap(find.text('Delete card'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't delete the card"), findsOneWidget);
      expect(find.text(detail), findsNWidgets(2));
      expect(find.text('Question 1'), findsOneWidget);
    }
  });
}
