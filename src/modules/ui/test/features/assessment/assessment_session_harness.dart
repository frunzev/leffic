import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/assessment/assessment_api.dart';
import 'package:leffic/features/assessment/assessment_models.dart';
import 'package:leffic/features/assessment/assessment_session.dart';
import 'package:leffic/features/assessment/test_position.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_field.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import 'assessment_fakes.dart';
import 'assessment_generators.dart';

const String missedReviewSession = 'missed-session';

class SessionHarness {
  SessionHarness({
    required this.perPage,
    required this.totalItems,
    this.missedItemIds = const [],
  });

  final int perPage;
  final int totalItems;
  final List<int> missedItemIds;
  final RememberedProgress memory = RememberedProgress(null);
  final List<int> loadedPages = [];
  final List<(String, int)> loadedMissedPages = [];
  late final FakeBackend backend = FakeBackend({
    '/review-test-item': answerWith({'msg': 'Saved!'}),
    '/test-session-results': answerWith({
      'correct': totalItems - missedItemIds.length,
      'missed_item_ids': missedItemIds,
    }),
    '/update-test-item': answerWith({'msg': 'Test item updated!'}),
  });

  TestItemsPage pageNumbered(int pageNumber) {
    return TestItemsPage.fromJson(
      testPageJson(
        pageNumber: pageNumber,
        perPage: perPage,
        totalItems: totalItems,
      ),
    );
  }

  Future<TestItemsPage> loadPage(int pageNumber) async {
    loadedPages.add(pageNumber);

    return pageNumbered(pageNumber);
  }

  Future<TestItemsPage> loadMissedPage(
    String finishedSession,
    int pageNumber,
  ) async {
    loadedMissedPages.add((finishedSession, pageNumber));

    return TestItemsPage.fromJson(
      chosenItemsPageJson(
        pageNumber: pageNumber,
        perPage: perPage,
        itemIds: missedItemIds,
        testSession: missedReviewSession,
      ),
    );
  }

  Future<void> pump(WidgetTester tester, {required TestPosition start}) async {
    await tester.pumpWidget(
      hostedPlainly(
        AssessmentSession(
          api: AssessmentApi(backend.client()),
          loadPage: loadPage,
          loadMissedPage: loadMissedPage,
          memory: memory,
          opened: (
            page: pageNumbered(start.pageNumber),
            itemIndex: start.itemIndex,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

Finder questionActionsButton() {
  return find.byWidgetPredicate(
    (widget) => widget is DesignIconButton && widget.icon == DesignIcons.dots,
  );
}

Future<void> openQuestionEditor(WidgetTester tester) async {
  await tester.tap(questionActionsButton());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Edit question'));
  await tester.pumpAndSettle();
}

Finder questionField() {
  return find.descendant(
    of: find.widgetWithText(DesignField, 'Question'),
    matching: find.byType(TextField),
  );
}
