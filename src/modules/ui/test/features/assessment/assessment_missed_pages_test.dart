import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leffic/features/assessment/folder_test_page.dart';
import 'package:leffic/features/assessment/test_page.dart';
import 'package:leffic/shared/navigation/routes.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import '../../support/property.dart';
import 'assessment_generators.dart';
import 'temporary_support_directory.dart';

typedef _PageFor = Widget Function(UnitArguments arguments);

Future<http.Response> _missedAwareItems(http.Request request) async {
  final isMissedReview = request.url.queryParameters.containsKey(
    'missed_in_session',
  );
  final pageJson = testPageJson(
    pageNumber: 1,
    perPage: 10,
    totalItems: 1,
    testSession: isMissedReview ? 'missed-session' : 'session-1',
  );

  return jsonReply(pageJson);
}

Future<void> _expectMissedReview(
  WidgetTester tester, {
  required _PageFor pageFor,
  required String scopeKey,
}) async {
  useTemporarySupportDirectory();

  for (final scopeId in examplesOf(tokenOf, runs: 3)) {
    final backend = FakeBackend({
      '/test-items': _missedAwareItems,
      '/review-test-item': answerWith({'msg': 'Saved!'}),
      '/test-session-results': answerWith({
        'correct': 0,
        'missed_item_ids': [1],
      }),
    });

    await pumpOnTopOfFolder(
      tester,
      client: backend.client(),
      page: pageFor(UnitArguments(id: scopeId, name: 'Scope')),
    );
    await tester.tap(find.text('Right 1'));
    await tester.pump();
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review the 1 missed'));
    await tester.pumpAndSettle();

    final asked = backend.sentTo('/test-items').last.url.queryParameters;

    expect(asked, {
      scopeKey: scopeId,
      'missed_in_session': 'session-1',
      'page': '1',
      'per_page': '10',
    });
    expect(find.text('Question 1 of 1'), findsOneWidget);
  }
}

void main() {
  testWidgets('TestPage property reviews the missed of its test', (
    tester,
  ) async {
    useDesktopSurface(tester);

    await _expectMissedReview(
      tester,
      pageFor: (arguments) => TestPage(arguments: arguments),
      scopeKey: 'test_id',
    );
  });

  testWidgets('FolderTestPage property reviews the missed of its folder', (
    tester,
  ) async {
    useDesktopSurface(tester);

    await _expectMissedReview(
      tester,
      pageFor: (arguments) => FolderTestPage(arguments: arguments),
      scopeKey: 'folder_id',
    );
  });
}
