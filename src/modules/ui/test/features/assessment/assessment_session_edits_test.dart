import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/assessment/test_position.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import '../../support/property.dart';
import 'assessment_generators.dart';
import 'assessment_session_harness.dart';

void main() {
  testWidgets('AssessmentSession property saves an edited question', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final question in examplesOf(generatedQuestion, runs: 3)) {
      final harness = SessionHarness(perPage: 3, totalItems: 3);

      await harness.pump(tester, start: TestPosition.start);
      await openQuestionEditor(tester);
      await tester.enterText(questionField(), question);
      await tester.tap(find.text('Save question'));
      await tester.pumpAndSettle();

      final update = sentBody(
        harness.backend.sentTo('/update-test-item').single,
      );

      expect(update['test_item_id'], 1);
      expect(update['content'], {
        'question': question,
        'true_option': 'Right 1',
        'false_options': ['Wrong 1'],
      });
      expect(harness.loadedPages, [1]);
    }
  });

  testWidgets('AssessmentSession property reports a failed edit', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final detail in examplesOf(wordOf, runs: 3)) {
      final harness = SessionHarness(perPage: 3, totalItems: 3);

      harness.backend.replies['/update-test-item'] = failWith(500, detail);

      await harness.pump(tester, start: TestPosition.start);
      await openQuestionEditor(tester);
      await tester.enterText(questionField(), 'Changed?');
      await tester.tap(find.text('Save question'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't save the question"), findsOneWidget);
      expect(find.text(detail), findsOneWidget);
      expect(find.text('Question 1?'), findsOneWidget);
    }
  });
}
