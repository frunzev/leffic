import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leffic/features/assessment/test_position.dart';
import 'package:leffic/shared/design/design_button.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import '../../support/property.dart';
import 'assessment_session_harness.dart';

typedef _TestShape = (int perPage, int totalItems);

List<_TestShape> _shapes(int runs) {
  return examplesOf(
    (random) => (integerBetween(random, 1, 4), integerBetween(random, 1, 9)),
    runs: runs,
  );
}

Future<void> _answerAndGoOn(WidgetTester tester, int number) async {
  await tester.tap(find.text('Right $number'));
  await tester.pump();
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
}

List<Object?> _sentItemIds(List<http.Request> requests) {
  final ids = <Object?>[];

  for (final request in requests) {
    ids.add(sentBody(request)['test_item_id']);
  }

  return ids;
}

void main() {
  testWidgets('AssessmentSession property walks every page to the result', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final (perPage, totalItems) in _shapes(5)) {
      final harness = SessionHarness(perPage: perPage, totalItems: totalItems);

      await harness.pump(tester, start: TestPosition.start);

      for (var number = 1; number < totalItems; number++) {
        expect(find.text('Question $number of $totalItems'), findsOneWidget);
        await _answerAndGoOn(tester, number);
      }

      await tester.tap(find.text('Right $totalItems'));
      await tester.pump();
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();

      final reviews = harness.backend.sentTo('/review-test-item');

      expect(find.text('$totalItems / $totalItems'), findsOneWidget);
      expect(
        _sentItemIds(reviews),
        List.generate(totalItems, (index) => index + 1),
      );
      expect(sentBody(reviews.first)['answers'], [0]);
      expect(harness.memory.history.last, isNull);
      expect(harness.loadedPages.length, (totalItems - 1) ~/ perPage);
    }
  });

  testWidgets('AssessmentSession property remembers every move', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final (perPage, totalItems) in _shapes(4)) {
      final harness = SessionHarness(
        perPage: perPage,
        totalItems: totalItems + 1,
      );

      await harness.pump(tester, start: TestPosition.start);

      for (var number = 1; number <= totalItems; number++) {
        await _answerAndGoOn(tester, number);

        final remembered = harness.memory.position!;

        expect(remembered.pageNumber, number ~/ perPage + 1);
        expect(remembered.itemIndex, number % perPage);
      }
    }
  });

  testWidgets('AssessmentSession property goes back across pages', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final (perPage, extraItems) in _shapes(4)) {
      final totalItems = perPage + extraItems;
      final harness = SessionHarness(perPage: perPage, totalItems: totalItems);

      await harness.pump(
        tester,
        start: const TestPosition(pageNumber: 2, itemIndex: 0),
      );

      expect(
        find.text('Question ${perPage + 1} of $totalItems'),
        findsOneWidget,
      );

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Question $perPage of $totalItems'), findsOneWidget);
      expect(harness.loadedPages, [1]);
      expect(harness.memory.position?.itemIndex, perPage - 1);
      expect(harness.backend.sentTo('/review-test-item'), isEmpty);
    }
  });

  testWidgets('AssessmentSession property cannot go back from the first', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final (perPage, totalItems) in _shapes(3)) {
      final harness = SessionHarness(perPage: perPage, totalItems: totalItems);

      await harness.pump(tester, start: TestPosition.start);

      final backButton = tester.widget<DesignButton>(
        find.widgetWithText(DesignButton, 'Back'),
      );

      expect(backButton.onPressed, isNull);
    }
  });

  testWidgets('AssessmentSession property retakes from the first question', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final (perPage, totalItems) in _shapes(3)) {
      final harness = SessionHarness(perPage: perPage, totalItems: totalItems);
      final lastPage = (totalItems - 1) ~/ perPage + 1;
      final lastIndex = (totalItems - 1) % perPage;

      await harness.pump(
        tester,
        start: TestPosition(pageNumber: lastPage, itemIndex: lastIndex),
      );
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retake test'));
      await tester.pumpAndSettle();

      expect(find.text('Question 1 of $totalItems'), findsOneWidget);
      expect(harness.memory.position?.pageNumber, 1);
      expect(harness.memory.position?.itemIndex, 0);
      expect(harness.backend.sentTo('/review-test-item'), isEmpty);
    }
  });

  testWidgets('AssessmentSession property reports a failed answer', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final detail in examplesOf(wordOf, runs: 3)) {
      final harness = SessionHarness(perPage: 2, totalItems: 4);

      harness.backend.replies['/review-test-item'] = failWith(500, detail);

      await harness.pump(tester, start: TestPosition.start);
      await _answerAndGoOn(tester, 1);

      expect(find.text("Couldn't save your answer"), findsOneWidget);
      expect(find.text(detail), findsOneWidget);
      expect(find.text('Question 1 of 4'), findsOneWidget);
    }
  });

  testWidgets('AssessmentSession property explains an empty test', (
    tester,
  ) async {
    useDesktopSurface(tester);

    final harness = SessionHarness(perPage: 10, totalItems: 0);

    await harness.pump(tester, start: TestPosition.start);

    expect(find.text('This test has no questions yet'), findsOneWidget);
  });
}
