import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/flashcards/flashcard_models.dart';
import 'package:leffic/features/flashcards/interval_label.dart';
import 'package:leffic/features/flashcards/rating_button.dart';
import 'package:leffic/features/flashcards/rating_buttons.dart';
import 'package:leffic/shared/api/api_error.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_shadows.dart';
import 'package:leffic/shared/design/shortcut_chip.dart';
import 'package:leffic/shared/design/surface_box.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';
import 'flashcard_generators.dart';

const Map<FlashcardRating, ShortcutChipTone> _cssAccents = {
  FlashcardRating.again: ShortcutChipTone.again,
  FlashcardRating.hard: ShortcutChipTone.hard,
  FlashcardRating.good: ShortcutChipTone.good,
  FlashcardRating.easy: ShortcutChipTone.good,
};

Finder _ratingButton(FlashcardRating rating) {
  return find.ancestor(
    of: find.text(rating.label),
    matching: find.byType(RatingButton),
  );
}

SurfaceLook _lookOf(WidgetTester tester) {
  return tester
      .widget<SurfaceBox>(
        find.descendant(
          of: find.byType(RatingButton),
          matching: find.byType(SurfaceBox),
        ),
      )
      .look;
}

Future<void> _pumpRatingButton(
  WidgetTester tester,
  FlashcardRating rating,
  String intervalText,
) async {
  await tester.pumpWidget(
    hostedPlainly(
      Center(
        child: SizedBox(
          width: 174,
          child: RatingButton(
            rating: rating,
            intervalText: intervalText,
            onPressed: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('RatingButtons property labels each rating with its interval', (
    tester,
  ) async {
    for (final json in examplesOf(generatedIntervalsJson, runs: 10)) {
      final intervals = RatingIntervals.fromJson(json);

      await tester.pumpWidget(
        hostedPlainly(
          RatingButtons(
            key: UniqueKey(),
            loadIntervals: () async => intervals,
            onRate: (rating) {},
          ),
        ),
      );
      await tester.pump();

      for (final rating in FlashcardRating.values) {
        final label = intervalLabel(intervals.secondsFor(rating));

        expect(
          find.descendant(
            of: _ratingButton(rating),
            matching: find.text(label),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: _ratingButton(rating),
            matching: find.text('${rating.score}'),
          ),
          findsOneWidget,
        );
      }
    }
  });

  testWidgets('RatingButtons property reports the tapped rating', (
    tester,
  ) async {
    final chosen = examplesOf(
      (random) => oneOf(random, FlashcardRating.values),
      runs: 8,
    );
    final reported = <FlashcardRating>[];

    await tester.pumpWidget(
      hostedPlainly(
        RatingButtons(
          loadIntervals: () async =>
              RatingIntervals.fromJson({'1': 1, '2': 2, '3': 3, '4': 4}),
          onRate: reported.add,
        ),
      ),
    );
    await tester.pump();

    for (final rating in chosen) {
      await tester.tap(_ratingButton(rating));
    }

    expect(reported, chosen);
  });

  testWidgets('RatingButtons property shows why intervals are missing', (
    tester,
  ) async {
    for (final detail in examplesOf(wordOf, runs: 5)) {
      await tester.pumpWidget(
        hostedPlainly(
          RatingButtons(
            key: UniqueKey(),
            loadIntervals: () async => throw ApiError(
              statusCode: 422,
              path: '/rating-intervals',
              detail: detail,
            ),
            onRate: (rating) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text(detail), findsOneWidget);
      expect(_ratingButton(FlashcardRating.good), findsOneWidget);
    }
  });

  testWidgets('RatingButtons property is four 56px columns 8px apart', (
    tester,
  ) async {
    final widths = examplesOf(
      (random) => integerBetween(random, 520, 720).toDouble(),
      runs: 6,
    );

    for (final width in widths) {
      useDesktopSurface(tester);
      await tester.pumpWidget(
        hostedPlainly(
          Center(
            child: SizedBox(
              width: width,
              child: RatingButtons(
                key: UniqueKey(),
                loadIntervals: () async =>
                    RatingIntervals.fromJson({'1': 1, '2': 2, '3': 3, '4': 4}),
                onRate: (rating) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final buttons = [
        for (final rating in FlashcardRating.values)
          tester.getRect(_ratingButton(rating)),
      ];

      for (var index = 0; index < buttons.length; index++) {
        expect(buttons[index].width, closeTo((width - 24) / 4, 0.01));
        expect(buttons[index].height, 56);

        if (index > 0) {
          expect(
            buttons[index].left - buttons[index - 1].right,
            closeTo(8, 0.01),
          );
        }
      }
    }
  });

  testWidgets('RatingButton property is the .rating card with its accent', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);
    final shadows = DesignShadows.forBrightness(Brightness.light);
    final examples = examplesOf(
      (random) => (
        oneOf(random, FlashcardRating.values),
        oneOf(random, ['1 min', '8 min', '3 days', '12 days']),
      ),
      runs: 8,
    );

    for (final (rating, intervalText) in examples) {
      await _pumpRatingButton(tester, rating, intervalText);

      final button = tester.getRect(find.byType(RatingButton));
      final chip = tester.widget<ShortcutChip>(find.byType(ShortcutChip));
      final chipRect = tester.getRect(find.byType(ShortcutChip));
      final label = tester.getRect(find.text(rating.label));
      final interval = tester.getRect(find.text(intervalText));
      final labelStyle = renderedStyleOf(tester, rating.label);
      final intervalStyle = renderedStyleOf(tester, intervalText);
      final surface = tester.widget<SurfaceBox>(
        find.descendant(
          of: find.byType(RatingButton),
          matching: find.byType(SurfaceBox),
        ),
      );

      expect(button.height, 56);
      expect(surface.borderRadius, 10);
      expect(surface.look.fill, colors.surface);
      expect(surface.look.border, BorderSide(color: colors.lineStrong));
      expect(surface.look.shadows, shadows.raised);
      expect(chip.label, '${rating.score}');
      expect(chip.tone, _cssAccents[rating]);
      expect(chipRect.left - button.left, 17);
      expect(chipRect.center.dy, button.center.dy);
      expect(label.left - chipRect.right, 12);
      expect(interval.left, label.left);
      expect(label.center.dy - button.top, closeTo(14.5, 0.01));
      expect(interval.center.dy - button.top, closeTo(41.5, 0.01));
      expect(labelStyle.fontSize, 14);
      expect(labelStyle.fontWeight, FontWeight.w600);
      expect(labelStyle.color, colors.ink);
      expect(intervalStyle.fontSize, 12);
      expect(intervalStyle.color, colors.inkTertiary);
      expect(intervalStyle.fontFeatures, [const FontFeature.tabularFigures()]);
    }
  });

  testWidgets('RatingButton property hovers and presses like .rating', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);
    final shadows = DesignShadows.forBrightness(Brightness.light);

    for (final rating in FlashcardRating.values) {
      await _pumpRatingButton(tester, rating, '1 min');

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);

      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(RatingButton)));
      await tester.pump();

      expect(_lookOf(tester).fill, colors.surfaceSecondary);
      expect(_lookOf(tester).border, BorderSide(color: colors.lineHover));

      await mouse.down(tester.getCenter(find.byType(RatingButton)));
      await tester.pump();

      expect(_lookOf(tester).fill, colors.surfaceTertiary);
      expect(_lookOf(tester).border, BorderSide(color: colors.lineHover));
      expect(_lookOf(tester).shadows, shadows.raised);

      await mouse.up();
      await mouse.removePointer();
    }
  });
}
