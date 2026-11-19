import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/flashcards/flashcard_models.dart';
import 'package:leffic/features/flashcards/review_finished_view.dart';
import 'package:leffic/features/flashcards/review_meter.dart';
import 'package:leffic/features/flashcards/review_queue.dart';
import 'package:leffic/features/flashcards/review_shortcuts.dart';
import 'package:leffic/features/flashcards/show_answer_button.dart';
import 'package:leffic/shared/design/button_look.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';
import 'package:leffic/shared/design/meter.dart';
import 'package:leffic/shared/design/shortcut_chip.dart';
import 'package:leffic/shared/design/state_block.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

const List<LogicalKeyboardKey> _digitKeys = [
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
];

Future<void> _pressRatingKey(WidgetTester tester, FlashcardRating rating) {
  return tester.sendKeyEvent(
    _digitKeys[rating.index],
    character: '${rating.score}',
  );
}

void main() {
  testWidgets('ReviewMeter property shows reviewed, total and left', (
    tester,
  ) async {
    final queues = examplesOf(
      (random) => ReviewQueue(
        cards: const [],
        totalToReview: integerBetween(random, 1, 60),
        reviewedCount: integerBetween(random, 0, 60),
      ),
      runs: 10,
    );

    for (final queue in queues) {
      await tester.pumpWidget(hostedPlainly(ReviewMeter(queue: queue)));

      final meter = tester.widget<MeterBlock>(find.byType(MeterBlock));

      expect(
        meter.startLabel,
        'Reviewed ${queue.reviewedCount} of ${queue.totalToReview}',
      );
      expect(meter.endLabel, '${queue.leftCount} left');
      expect(meter.fraction, queue.completedShare);
    }
  });

  testWidgets('ReviewFinishedView property goes back when asked', (
    tester,
  ) async {
    final taps = examplesOf((random) => integerBetween(random, 1, 4), runs: 4);

    for (final tapCount in taps) {
      var backCount = 0;

      await tester.pumpWidget(
        hostedPlainly(ReviewFinishedView(onBackToFolder: () => backCount++)),
      );

      for (var tap = 0; tap < tapCount; tap++) {
        await tester.tap(find.text('Back to folder'));
      }

      final state = tester.widget<StateBlock>(find.byType(StateBlock));
      final back = tester.widget<DesignButton>(find.byType(DesignButton));

      expect(state.icon, DesignIcons.success);
      expect(state.title, "You're done for today");
      expect(
        state.text,
        'Every card in this deck is scheduled. The next one comes back '
        "when you're about to forget it.",
      );
      expect(back.variant, ButtonVariant.standard);
      expect(back.size, ButtonSize.regular);
      expect(backCount, tapCount);
    }
  });

  testWidgets('ReviewShortcuts property reveals with Space only if allowed', (
    tester,
  ) async {
    for (final isRevealAllowed in [true, false]) {
      var revealCount = 0;

      await tester.pumpWidget(
        hostedPlainly(
          ReviewShortcuts(
            key: UniqueKey(),
            onReveal: isRevealAllowed ? () => revealCount++ : null,
            onRate: null,
            child: const Text('card'),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await _pressRatingKey(tester, FlashcardRating.good);

      expect(revealCount, isRevealAllowed ? 1 : 0);
    }
  });

  testWidgets('ReviewShortcuts property rates with digit keys if allowed', (
    tester,
  ) async {
    final pressed = examplesOf(
      (random) => oneOf(random, FlashcardRating.values),
      runs: 12,
    );
    final reported = <FlashcardRating>[];

    await tester.pumpWidget(
      hostedPlainly(
        ReviewShortcuts(
          onReveal: null,
          onRate: reported.add,
          child: const Text('card'),
        ),
      ),
    );
    await tester.pump();

    for (final rating in pressed) {
      await _pressRatingKey(tester, rating);
    }

    await tester.sendKeyEvent(LogicalKeyboardKey.space);

    expect(reported, pressed);
  });

  testWidgets('ShowAnswerButton property reveals on every press', (
    tester,
  ) async {
    final taps = examplesOf((random) => integerBetween(random, 1, 4), runs: 4);

    for (final tapCount in taps) {
      var pressCount = 0;

      await tester.pumpWidget(
        hostedPlainly(ShowAnswerButton(onPressed: () => pressCount++)),
      );

      for (var tap = 0; tap < tapCount; tap++) {
        await tester.tap(find.text('Show answer'));
      }

      expect(pressCount, tapCount);
    }
  });

  testWidgets('ShowAnswerButton property is a full-width large primary', (
    tester,
  ) async {
    final widths = examplesOf(
      (random) => integerBetween(random, 300, 720).toDouble(),
      runs: 5,
    );

    for (final width in widths) {
      await tester.pumpWidget(
        hostedPlainly(
          Center(
            child: SizedBox(
              width: width,
              child: ShowAnswerButton(onPressed: () {}),
            ),
          ),
        ),
      );

      final button = tester.widget<DesignButton>(find.byType(DesignButton));
      final chip = button.trailing! as ShortcutChip;

      expect(button.label, 'Show answer');
      expect(button.variant, ButtonVariant.primary);
      expect(button.size, ButtonSize.large);
      expect(chip.label, 'Space');
      expect(chip.tone, ShortcutChipTone.onBrand);
      expect(tester.getSize(find.byType(DesignButton)), Size(width, 44));
    }
  });
}
