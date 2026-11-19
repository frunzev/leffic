import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/flashcards/deck_review_page.dart';
import 'package:leffic/features/flashcards/flashcard_review.dart';
import 'package:leffic/features/flashcards/flashcards_api.dart';
import 'package:leffic/features/flashcards/folder_review_page.dart';
import 'package:leffic/shared/design/design_overlay.dart';
import 'package:leffic/shared/navigation/routes.dart';
import 'package:leffic/shared/widgets/app_shell.dart';
import 'package:leffic/shared/widgets/review_stage.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import '../../support/property.dart';
import 'flashcard_generators.dart';

typedef _PageFor = Widget Function(UnitArguments arguments);
typedef _FrameCheck = void Function(
  WidgetTester tester,
  UnitArguments arguments,
);

const Map<String, int> _intervals = {'1': 30, '2': 600, '3': 900, '4': 9000};
const Map<String, Object?> _nothingDue = {
  'flashcards': <Object?>[],
  'total_flashcards': 0,
};

Map<String, Object?> _dueOneCard() {
  return {
    'flashcards': [
      {
        'id': 41,
        'type': 'basic',
        'next_review': null,
        'content': {'front': 'What is DNA?', 'back': 'A molecule'},
        'created_at': '2026-11-01 08:00:00',
        'fsrs_card': null,
      },
    ],
    'total_flashcards': 1,
  };
}

Future<void> _expectScopedRequests(
  WidgetTester tester, {
  required _PageFor pageFor,
  required String scopeKey,
  required _FrameCheck checkFrame,
}) async {
  final examples = examplesOf(
    (random) => (
      oneOf(random, [homeFolderId, tokenOf(random)]),
      wordOf(random),
      generatedDueJson(random),
    ),
    runs: 4,
  );

  for (final (scopeId, name, dueJson) in examples) {
    final backend = FakeBackend({'/flashcards': answerWith(dueJson)});
    final arguments = UnitArguments(id: scopeId, name: name);

    await pumpOnTopOfFolder(
      tester,
      client: backend.client(),
      page: pageFor(arguments),
    );

    expect(backend.sentTo('/flashcards').single.url.queryParameters, {
      scopeKey: scopeId,
    });
    expect(find.byType(ReviewStage), findsOneWidget);
    checkFrame(tester, arguments);
  }
}

void _expectInShell(WidgetTester tester, UnitArguments arguments) {
  final shell = tester.widget<AppShell>(find.byType(AppShell));

  expect(shell.selectedRoute, Routes.deckReview);
  expect(find.byType(DesignOverlay), findsNothing);
}

void _expectInOverlay(WidgetTester tester, UnitArguments arguments) {
  final overlay = tester.widget<DesignOverlay>(find.byType(DesignOverlay));

  expect(overlay.title, 'Mixed review · ${arguments.name}');
  expect(overlay.closeLabel, 'End review');
  expect(find.byType(AppShell), findsNothing);
}

Future<void> _pumpReview(WidgetTester tester, FakeBackend backend) async {
  final api = FlashcardsApi(backend.client());

  await pumpOnTopOfFolder(
    tester,
    client: backend.client(),
    page: FlashcardReview(api: api, loadDue: () => api.deckFlashcards('deck')),
  );
}

void main() {
  testWidgets('DeckReviewPage property asks for the due cards of its deck', (
    tester,
  ) async {
    useDesktopSurface(tester);

    await _expectScopedRequests(
      tester,
      pageFor: (arguments) => DeckReviewPage(arguments: arguments),
      scopeKey: 'flashcard_deck_id',
      checkFrame: _expectInShell,
    );
  });

  testWidgets('FolderReviewPage property asks for the due cards of a folder', (
    tester,
  ) async {
    useDesktopSurface(tester);

    await _expectScopedRequests(
      tester,
      pageFor: (arguments) => FolderReviewPage(arguments: arguments),
      scopeKey: 'folder_id',
      checkFrame: _expectInOverlay,
    );
  });

  testWidgets('FolderReviewPage property ends the review from its bar', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final name in examplesOf(wordOf, runs: 3)) {
      final backend = FakeBackend({'/flashcards': answerWith(_dueOneCard())});

      await pumpOnTopOfFolder(
        tester,
        client: backend.client(),
        page: FolderReviewPage(
          arguments: UnitArguments(id: homeFolderId, name: name),
        ),
      );
      await tester.tap(find.bySemanticsLabel('End review'));
      await tester.pumpAndSettle();

      expect(find.text(folderPageText), findsOneWidget);
      expect(find.byType(DesignOverlay), findsNothing);
    }
  });

  testWidgets('FlashcardReview property goes back to the folder when done', (
    tester,
  ) async {
    useDesktopSurface(tester);

    await _pumpReview(
      tester,
      FakeBackend({'/flashcards': answerWith(_nothingDue)}),
    );
    await tester.tap(find.text('Back to folder'));
    await tester.pumpAndSettle();

    expect(find.text(folderPageText), findsOneWidget);
    expect(find.byType(ReviewStage), findsNothing);
  });

  testWidgets('FlashcardReview property reviews a card end to end', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final rating in ['Again', 'Hard', 'Good', 'Easy']) {
      var dueReplies = 0;
      final backend = FakeBackend({
        '/flashcards': (request) async {
          dueReplies++;

          if (dueReplies == 1) {
            return jsonReply(_dueOneCard());
          }

          return jsonReply(_nothingDue);
        },
        '/rating-intervals': answerWith(_intervals),
        '/review-flashcard': answerWith({
          'due_date': '2099-01-01 00:00:00',
          'new_fsrs_card': {'state': 2},
        }),
      });

      await _pumpReview(tester, backend);
      await tester.tap(find.text('Show answer'));
      await tester.pumpAndSettle();

      expect(find.text('A molecule'), findsOneWidget);

      await tester.tap(find.text(rating));
      await tester.pumpAndSettle();

      expect(find.text("You're done for today"), findsOneWidget);
      expect(backend.sentTo('/flashcards').length, 2);
    }
  });

  testWidgets('FlashcardReview property shows a failure it can retry', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final detail in examplesOf(wordOf, runs: 3)) {
      final backend = FakeBackend({'/flashcards': failWith(404, detail)});

      await _pumpReview(tester, backend);

      expect(find.text(detail), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    }
  });
}
