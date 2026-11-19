import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/assessment/empty_test_view.dart';
import 'package:leffic/features/assessment/test_card.dart';
import 'package:leffic/features/assessment/test_result_view.dart';
import 'package:leffic/shared/design/button_look.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_metrics.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';
import 'package:leffic/shared/design/section_label.dart';
import 'package:leffic/shared/design/state_block.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const double _resultGap = 12;
const double _actionsGap = 24;
const double _buttonGap = 8;
const int _detailCharacters = 46;

typedef _Score = (int correctCount, int totalItems, int missedCount);

List<_Score> _scores(int runs, {required int fewestMissed}) {
  return examplesOf((random) {
    final totalItems = integerBetween(random, 1, 40);
    final correctCount = integerBetween(random, 0, totalItems - fewestMissed);
    final missedCount = integerBetween(
      random,
      fewestMissed,
      totalItems - correctCount,
    );

    return (correctCount, totalItems, missedCount);
  }, runs: runs);
}

Widget _resultOf(_Score score, {required List<String> calls}) {
  final (correctCount, totalItems, missedCount) = score;

  return hostedInTheme(
    Center(
      child: SizedBox(
        width: 720,
        child: TestResultView(
          correctCount: correctCount,
          totalItems: totalItems,
          missedCount: missedCount,
          onReviewMissed: () => calls.add('review'),
          onRetake: () => calls.add('retake'),
          onBackToFolder: () => calls.add('back'),
        ),
      ),
    ),
    brightness: Brightness.light,
  );
}

TextStyle _detailStyleOf(WidgetTester tester) {
  final detailText = tester.widget<RichText>(
    find.descendant(
      of: find.textContaining('you missed'),
      matching: find.byType(RichText),
    ),
  );

  return detailText.text.style!;
}

void main() {
  testWidgets('TestResultView property offers to review what was missed', (
    tester,
  ) async {
    for (final score in _scores(8, fewestMissed: 1)) {
      final (correctCount, totalItems, missedCount) = score;
      final calls = <String>[];

      await tester.pumpWidget(_resultOf(score, calls: calls));

      expect(find.text('$correctCount / $totalItems'), findsOneWidget);
      expect(
        find.textContaining('The $missedCount you missed'),
        findsOneWidget,
      );
      expect(find.text('Back to folder'), findsNothing);

      await tester.tap(find.text('Review the $missedCount missed'));
      await tester.tap(find.text('Retake test'));

      expect(calls, ['review', 'retake']);
    }
  });

  testWidgets('TestResultView property goes back when nothing was missed', (
    tester,
  ) async {
    for (final score in _scores(6, fewestMissed: 0)) {
      final (correctCount, totalItems, _) = score;
      final calls = <String>[];

      await tester.pumpWidget(
        _resultOf((correctCount, totalItems, 0), calls: calls),
      );

      expect(find.textContaining('Review the'), findsNothing);

      await tester.tap(find.text('Retake test'));
      await tester.tap(find.text('Back to folder'));

      expect(calls, ['retake', 'back']);
      expect(
        tester
            .widget<DesignButton>(
              find.widgetWithText(DesignButton, 'Retake test'),
            )
            .variant,
        ButtonVariant.primary,
      );
    }
  });

  testWidgets('TestResultView property lays out the .test-result card', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final score in _scores(6, fewestMissed: 1)) {
      final (correctCount, totalItems, missedCount) = score;
      final scoreText = '$correctCount / $totalItems';

      await tester.pumpWidget(_resultOf(score, calls: []));

      final card = tester.getRect(find.byType(TestCard));
      final label = tester.getRect(find.byType(SectionLabel));
      final scoreRect = tester.getRect(find.text(scoreText));
      final detail = tester.getRect(find.textContaining('you missed'));
      final reviewButton = find.widgetWithText(
        DesignButton,
        'Review the $missedCount missed',
      );
      final retakeButton = find.widgetWithText(DesignButton, 'Retake test');
      final scoreStyle = renderedStyleOf(tester, scoreText);
      final detailStyle = _detailStyleOf(tester);
      final reviewRect = tester.getRect(reviewButton);
      final retakeRect = tester.getRect(retakeButton);

      expect(find.text('Test complete'), findsOneWidget);
      expect(scoreRect.top, label.bottom + _resultGap);
      expect(detail.top, scoreRect.bottom + _resultGap);
      expect(reviewRect.top, detail.bottom + _actionsGap);
      expect(retakeRect.top, reviewRect.top);
      expect(retakeRect.left, reviewRect.right + _buttonGap);
      expect(
        (reviewRect.left + retakeRect.right) / 2,
        closeTo(card.center.dx, 0.5),
      );
      expect(label.center.dx, closeTo(card.center.dx, 0.5));
      expect(scoreRect.center.dx, closeTo(card.center.dx, 0.5));
      expect(detail.center.dx, closeTo(card.center.dx, 0.5));
      expect(
        detail.width,
        lessThanOrEqualTo(
          widthOfCharacters(_detailCharacters, textSize: TextSizes.medium),
        ),
      );
      expect(scoreStyle.fontSize, 48);
      expect(scoreStyle.fontWeight, FontWeight.w600);
      expect(scoreStyle.height, 1);
      expect(scoreStyle.letterSpacing, closeTo(0.35 - 0.96, 1e-9));
      expect(scoreStyle.fontFeatures, [const FontFeature.tabularFigures()]);
      expect(scoreRect.height, 48);
      expect(detailStyle.fontSize, 16);
      expect(detailStyle.color, colors.inkSecondary);
      expect(
        tester.widget<DesignButton>(reviewButton).variant,
        ButtonVariant.primary,
      );
      expect(
        tester.widget<DesignButton>(retakeButton).variant,
        ButtonVariant.standard,
      );
    }
  });

  testWidgets('EmptyTestView property is the .state block and goes back', (
    tester,
  ) async {
    final taps = examplesOf((random) => integerBetween(random, 1, 3), runs: 3);

    for (final tapCount in taps) {
      var backCount = 0;

      await tester.pumpWidget(
        hostedPlainly(EmptyTestView(onBackToFolder: () => backCount++)),
      );

      for (var tap = 0; tap < tapCount; tap++) {
        await tester.tap(find.text('Back to folder'));
      }

      final state = tester.widget<StateBlock>(find.byType(StateBlock));
      final action = state.action! as DesignButton;

      expect(state.icon, DesignIcons.test);
      expect(state.title, 'This test has no questions yet');
      expect(
        state.text,
        'Import a file, a link or a topic into this folder and questions '
        'are generated with it.',
      );
      expect(action.variant, ButtonVariant.standard);
      expect(backCount, tapCount);
    }
  });
}
