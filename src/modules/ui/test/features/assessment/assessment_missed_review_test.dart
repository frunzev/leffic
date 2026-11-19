import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/assessment/test_position.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import '../../support/property.dart';
import 'assessment_session_harness.dart';

typedef _MissedShape = (int perPage, int totalItems, List<int> missedItemIds);

List<int> _missedSubset(Random random, int totalItems) {
  final missedItemIds = <int>[];

  for (var itemId = 1; itemId <= totalItems; itemId++) {
    if (random.nextBool()) {
      missedItemIds.add(itemId);
    }
  }

  if (missedItemIds.isEmpty) {
    missedItemIds.add(integerBetween(random, 1, totalItems));
  }

  return missedItemIds;
}

List<_MissedShape> _shapes(int runs) {
  return examplesOf((random) {
    final totalItems = integerBetween(random, 1, 7);

    return (
      integerBetween(random, 1, 3),
      totalItems,
      _missedSubset(random, totalItems),
    );
  }, runs: runs);
}

TestPosition _lastPosition(int perPage, int totalItems) {
  return TestPosition(
    pageNumber: (totalItems - 1) ~/ perPage + 1,
    itemIndex: (totalItems - 1) % perPage,
  );
}

Future<void> _finish(WidgetTester tester) async {
  await tester.tap(find.text('Finish'));
  await tester.pumpAndSettle();
}

Future<void> _answerEveryMissed(
  WidgetTester tester,
  List<int> missedItemIds,
) async {
  for (final itemId in missedItemIds) {
    await tester.tap(find.text('Right $itemId'));
    await tester.pump();

    final isLast = itemId == missedItemIds.last;

    await tester.tap(find.text(isLast ? 'Finish' : 'Next'));
    await tester.pumpAndSettle();
  }
}

List<Object?> _reviewedIn(SessionHarness harness, String testSession) {
  final itemIds = <Object?>[];

  for (final request in harness.backend.sentTo('/review-test-item')) {
    final body = sentBody(request);

    if (body['test_session'] == testSession) {
      itemIds.add(body['test_item_id']);
    }
  }

  return itemIds;
}

void main() {
  testWidgets('AssessmentSession property reviews only the missed items', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final (perPage, totalItems, missedItemIds) in _shapes(5)) {
      final harness = SessionHarness(
        perPage: perPage,
        totalItems: totalItems,
        missedItemIds: missedItemIds,
      );
      final missedCount = missedItemIds.length;

      await harness.pump(tester, start: _lastPosition(perPage, totalItems));
      await _finish(tester);

      final rememberedBeforeReview = List.of(harness.memory.history);

      await tester.tap(find.text('Review the $missedCount missed'));
      await tester.pumpAndSettle();

      expect(find.text('Question 1 of $missedCount'), findsOneWidget);
      expect(harness.loadedMissedPages.first, ('session-1', 1));

      await _answerEveryMissed(tester, missedItemIds);

      final results = harness.backend.sentTo('/test-session-results');

      expect(_reviewedIn(harness, missedReviewSession), missedItemIds);
      expect(results.last.url.queryParameters, {
        'test_session': missedReviewSession,
      });
      expect(harness.memory.history, rememberedBeforeReview);
      expect(find.text('Review the $missedCount missed'), findsOneWidget);
    }
  });

  testWidgets('AssessmentSession property retakes the whole test after it', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final (perPage, totalItems, missedItemIds) in _shapes(3)) {
      final harness = SessionHarness(
        perPage: perPage,
        totalItems: totalItems,
        missedItemIds: missedItemIds,
      );

      await harness.pump(tester, start: _lastPosition(perPage, totalItems));
      await _finish(tester);
      await tester.tap(find.text('Review the ${missedItemIds.length} missed'));
      await tester.pumpAndSettle();
      await _answerEveryMissed(tester, missedItemIds);
      await tester.tap(find.text('Retake test'));
      await tester.pumpAndSettle();

      expect(find.text('Question 1 of $totalItems'), findsOneWidget);
      expect(harness.loadedPages.last, 1);
      expect(harness.memory.position?.pageNumber, 1);
      expect(harness.memory.position?.itemIndex, 0);
    }
  });

  testWidgets('AssessmentSession property offers no review without misses', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final (perPage, totalItems, _) in _shapes(3)) {
      final harness = SessionHarness(perPage: perPage, totalItems: totalItems);

      await harness.pump(tester, start: _lastPosition(perPage, totalItems));
      await _finish(tester);

      expect(find.text('$totalItems / $totalItems'), findsOneWidget);
      expect(find.textContaining('Review the'), findsNothing);
      expect(find.text('Retake test'), findsOneWidget);
      expect(harness.loadedMissedPages, isEmpty);
    }
  });
}
