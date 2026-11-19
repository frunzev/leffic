import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/assessment/assessment_api.dart';
import 'package:leffic/features/assessment/assessment_models.dart';
import 'package:leffic/features/assessment/assessment_review.dart';
import 'package:leffic/features/assessment/folder_test_page.dart';
import 'package:leffic/features/assessment/test_page.dart';
import 'package:leffic/features/assessment/test_position.dart';
import 'package:leffic/shared/design/design_overlay.dart';
import 'package:leffic/shared/navigation/routes.dart';
import 'package:leffic/shared/widgets/app_shell.dart';
import 'package:leffic/shared/widgets/review_stage.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import '../../support/property.dart';
import 'assessment_fakes.dart';
import 'assessment_generators.dart';
import 'temporary_support_directory.dart';

typedef _PageFor = Widget Function(UnitArguments arguments);
typedef _FrameCheck = void Function(
  WidgetTester tester,
  UnitArguments arguments,
);

Future<void> _expectScopedRequests(
  WidgetTester tester, {
  required _PageFor pageFor,
  required String scopeKey,
  required _FrameCheck checkFrame,
}) async {
  useTemporarySupportDirectory();

  final examples = examplesOf(
    (random) => (
      oneOf(random, [homeFolderId, tokenOf(random)]),
      wordOf(random),
      integerBetween(random, 1, 12),
    ),
    runs: 3,
  );

  for (final (scopeId, name, totalItems) in examples) {
    final backend = FakeBackend({
      '/test-items': answerWith(
        testPageJson(pageNumber: 1, perPage: 10, totalItems: totalItems),
      ),
      '/review-test-item': answerWith({'msg': 'Saved!'}),
    });

    final arguments = UnitArguments(id: scopeId, name: name);

    await pumpOnTopOfFolder(
      tester,
      client: backend.client(),
      page: pageFor(arguments),
    );

    final asked = backend.sentTo('/test-items').single.url.queryParameters;

    expect(asked[scopeKey], scopeId);
    expect(asked['page'], '1');
    expect(find.byType(ReviewStage), findsOneWidget);
    expect(find.text('Question 1 of $totalItems'), findsOneWidget);
    checkFrame(tester, arguments);
  }
}

Future<TestItemsPage> _noMissedItems(
  String finishedSession,
  int pageNumber,
) async {
  return TestItemsPage.fromJson(
    testPageJson(pageNumber: pageNumber, perPage: 10, totalItems: 0),
  );
}

void _expectInShell(WidgetTester tester, UnitArguments arguments) {
  final shell = tester.widget<AppShell>(find.byType(AppShell));

  expect(shell.selectedRoute, Routes.test);
  expect(find.byType(DesignOverlay), findsNothing);
}

void _expectInOverlay(WidgetTester tester, UnitArguments arguments) {
  final overlay = tester.widget<DesignOverlay>(find.byType(DesignOverlay));

  expect(overlay.title, 'Mixed test · ${arguments.name}');
  expect(overlay.closeLabel, 'End test');
  expect(find.byType(AppShell), findsNothing);
}

void main() {
  test('openRememberedTest property resumes where the test was left', () async {
    for (final (perPage, totalItems, pageNumber, itemIndex) in examplesOf(
      (random) => (
        integerBetween(random, 1, 5),
        integerBetween(random, 0, 20),
        integerBetween(random, 1, 6),
        integerBetween(random, 0, 6),
      ),
    )) {
      final loadedPages = <int>[];
      final memory = RememberedProgress(
        TestPosition(pageNumber: pageNumber, itemIndex: itemIndex),
      );

      final opened = await openRememberedTest(
        memory: memory,
        loadPage: (number) async {
          loadedPages.add(number);

          return TestItemsPage.fromJson(
            testPageJson(
              pageNumber: number,
              perPage: perPage,
              totalItems: totalItems,
            ),
          );
        },
      );
      final remembered = TestItemsPage.fromJson(
        testPageJson(
          pageNumber: pageNumber,
          perPage: perPage,
          totalItems: totalItems,
        ),
      );
      final isResumable =
          totalItems == 0 || itemIndex < remembered.items.length;

      expect(loadedPages.first, pageNumber);

      if (isResumable) {
        expect(opened.page.pageNumber, pageNumber);
        expect(opened.itemIndex, itemIndex);
      } else {
        expect(opened.page.pageNumber, firstPageNumber);
        expect(opened.itemIndex, 0);
        expect(opened.page.items, isNotEmpty);
      }
    }
  });

  testWidgets('AssessmentReview property opens the remembered question', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final itemIndex in examplesOf(
      (random) => integerBetween(random, 0, 4),
      runs: 4,
    )) {
      final backend = FakeBackend({});
      final memory = RememberedProgress(
        TestPosition(pageNumber: 2, itemIndex: itemIndex),
      );

      await pumpOnTopOfFolder(
        tester,
        client: backend.client(),
        page: AssessmentReview(
          api: AssessmentApi(backend.client()),
          memory: memory,
          loadPage: (number) async => TestItemsPage.fromJson(
            testPageJson(pageNumber: number, perPage: 5, totalItems: 10),
          ),
          loadMissedPage: _noMissedItems,
        ),
      );

      expect(find.text('Question ${6 + itemIndex} of 10'), findsOneWidget);
    }
  });

  testWidgets('AssessmentReview property goes back from an empty test', (
    tester,
  ) async {
    useDesktopSurface(tester);

    final backend = FakeBackend({});

    await pumpOnTopOfFolder(
      tester,
      client: backend.client(),
      page: AssessmentReview(
        api: AssessmentApi(backend.client()),
        memory: RememberedProgress(null),
        loadPage: (number) async => TestItemsPage.fromJson(
          testPageJson(pageNumber: number, perPage: 10, totalItems: 0),
        ),
        loadMissedPage: _noMissedItems,
      ),
    );
    await tester.tap(find.text('Back to folder'));
    await tester.pumpAndSettle();

    expect(find.text(folderPageText), findsOneWidget);
    expect(find.byType(ReviewStage), findsNothing);
  });

  testWidgets('AssessmentReview property shows a failure it can retry', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final detail in examplesOf(wordOf, runs: 3)) {
      final backend = FakeBackend({'/test-items': failWith(404, detail)});
      final api = AssessmentApi(backend.client());

      await pumpOnTopOfFolder(
        tester,
        client: backend.client(),
        page: AssessmentReview(
          api: api,
          memory: RememberedProgress(null),
          loadPage: (number) =>
              api.testItemsPage(testId: 'missing', pageNumber: number),
          loadMissedPage: _noMissedItems,
        ),
      );

      expect(find.text(detail), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    }
  });

  testWidgets('TestPage property asks for the items of its test', (
    tester,
  ) async {
    useDesktopSurface(tester);

    await _expectScopedRequests(
      tester,
      pageFor: (arguments) => TestPage(arguments: arguments),
      scopeKey: 'test_id',
      checkFrame: _expectInShell,
    );
  });

  testWidgets('FolderTestPage property asks for the items of its folder', (
    tester,
  ) async {
    useDesktopSurface(tester);

    await _expectScopedRequests(
      tester,
      pageFor: (arguments) => FolderTestPage(arguments: arguments),
      scopeKey: 'folder_id',
      checkFrame: _expectInOverlay,
    );
  });

  testWidgets('FolderTestPage property ends the test from its bar', (
    tester,
  ) async {
    useDesktopSurface(tester);
    useTemporarySupportDirectory();

    for (final name in examplesOf(wordOf, runs: 3)) {
      final backend = FakeBackend({
        '/test-items': answerWith(
          testPageJson(pageNumber: 1, perPage: 10, totalItems: 2),
        ),
      });

      await pumpOnTopOfFolder(
        tester,
        client: backend.client(),
        page: FolderTestPage(
          arguments: UnitArguments(id: homeFolderId, name: name),
        ),
      );
      await tester.tap(find.bySemanticsLabel('End test'));
      await tester.pumpAndSettle();

      expect(find.text(folderPageText), findsOneWidget);
      expect(find.byType(DesignOverlay), findsNothing);
    }
  });
}
