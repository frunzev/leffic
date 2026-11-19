import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/folders/due_models.dart';
import 'package:leffic/features/folders/due_section.dart';
import 'package:leffic/features/folders/unit_presentation.dart';
import 'package:leffic/shared/design/button_look.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_dropdown.dart';
import 'package:leffic/shared/design/design_shadows.dart';
import 'package:leffic/shared/design/icons/design_icon.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';
import 'package:leffic/shared/design/meter.dart';
import 'package:leffic/shared/design/surface_box.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const String _dueHeading = 'Due today';
const double _sectionWidth = 1200;

StudyCount _generatedCount(Random random) {
  return StudyCount(
    due: oneOf(random, [0, integerBetween(random, 1, 90)]),
    done: integerBetween(random, 0, 90),
  );
}

DueSummary _generatedSummary(Random random) {
  return DueSummary(
    flashcards: _generatedCount(random),
    testItems: _generatedCount(random),
    notes: _generatedCount(random),
  );
}

String _reviewLabel(DueSummary due) {
  return 'Review ${itemCountLabel(due.reviewableCount)}';
}

class _Reviews {
  final List<String> started = [];

  Widget section(DueSummary due) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: _sectionWidth,
        child: DueSection(
          due: due,
          onReviewFlashcards: () => started.add('flashcards'),
          onTakeTest: () => started.add('test'),
        ),
      ),
    );
  }
}

DesignButton _reviewButton(WidgetTester tester) {
  return tester.widget<DesignButton>(find.byType(DesignButton));
}

void main() {
  testWidgets('DueSection property shows every count and the progress', (
    tester,
  ) async {
    useDesktopSurface(tester);
    for (final due in examplesOf(_generatedSummary, runs: 10)) {
      await tester.pumpWidget(hostedInLightTheme(_Reviews().section(due)));

      final items = tester.widgetList<DueItem>(find.byType(DueItem)).toList();
      final meter = tester.widget<Meter>(find.byType(Meter));

      expect(
        find.text('${due.doneCount} of ${due.totalCount} done'),
        findsOneWidget,
      );
      expect(
        [for (final item in items) item.count],
        [due.flashcards.due, due.testItems.due, due.notes.due],
      );
      expect(
        [for (final item in items) item.label],
        ['flashcards', 'test items', 'notes'],
      );
      expect(
        [for (final item in items) item.icon],
        [DesignIcons.flashcards, DesignIcons.test, DesignIcons.note],
      );
      expect(meter.fraction, due.completedShare);
    }
  });

  testWidgets('DueItem property draws a .due-item, green once cleared', (
    tester,
  ) async {
    useDesktopSurface(tester);
    for (final example in examplesOf(
      (random) => (
        count: oneOf(random, [0, integerBetween(random, 1, 900)]),
        label: wordOf(random),
        brightness: oneOf(random, Brightness.values),
      ),
      runs: 10,
    )) {
      final colors = DesignColors.forBrightness(example.brightness);

      await tester.pumpWidget(
        hostedInTheme(
          Center(
            child: DueItem(
              icon: DesignIcons.flashcards,
              count: example.count,
              label: example.label,
            ),
          ),
          brightness: example.brightness,
        ),
      );

      final icon = tester.getRect(find.byType(DesignIcon));
      final count = tester.getRect(find.text('${example.count}'));
      final label = tester.getRect(find.text(example.label));
      final countStyle = renderedStyleOf(tester, '${example.count}');
      final labelStyle = renderedStyleOf(tester, example.label);
      final iconWidget = tester.widget<DesignIcon>(find.byType(DesignIcon));

      expect(icon.size, const Size.square(18));
      expect(iconWidget.color, colors.inkTertiary);
      expect(count.left - icon.right, 8);
      expect(label.left - count.right, 8);
      expect(count.center.dy, closeTo(icon.center.dy, 0.01));
      expect(label.center.dy, closeTo(icon.center.dy, 0.01));
      expect(countStyle.fontSize, 20);
      expect(countStyle.fontWeight, FontWeight.w600);
      expect(countStyle.color, example.count == 0 ? colors.good : colors.ink);
      expect(labelStyle.fontSize, 14);
      expect(labelStyle.color, colors.inkSecondary);
    }
  });

  testWidgets('DueSection property lays out like .due', (tester) async {
    useDesktopSurface(tester);
    for (final example in examplesOf(
      (random) => (
        due: _generatedSummary(random),
        brightness: oneOf(random, Brightness.values),
      ),
      runs: 8,
    )) {
      final colors = DesignColors.forBrightness(example.brightness);
      final shadows = DesignShadows.forBrightness(example.brightness);
      final progressText =
          '${example.due.doneCount} of ${example.due.totalCount} done';

      await tester.pumpWidget(
        hostedInTheme(
          _Reviews().section(example.due),
          brightness: example.brightness,
        ),
      );

      final card = tester.getRect(find.byType(DueSection));
      final surface = tester.widget<SurfaceBox>(find.byType(SurfaceBox).first);
      final heading = tester.getRect(find.text(_dueHeading));
      final progress = tester.getRect(find.text(progressText));
      final meter = tester.getRect(find.byType(Meter));
      final review = tester.getRect(find.byType(DesignButton));
      final progressStyle = renderedStyleOf(tester, progressText);

      expect(surface.borderRadius, 14);
      expect(surface.look.fill, colors.surface);
      expect(surface.look.border, BorderSide(color: colors.line));
      expect(surface.look.shadows, shadows.raised);
      expect(heading.topLeft - card.topLeft, const Offset(25, 25));
      expect(card.right - progress.right, 25);
      expect(progress.bottom, closeTo(heading.bottom, 0.01));
      expect(progressStyle.fontSize, 14);
      expect(progressStyle.color, colors.inkTertiary);
      expect(meter.top - heading.bottom, closeTo(8, 0.01));
      expect(meter.width, card.width - 50);
      expect(review.top - meter.bottom, closeTo(16, 0.01));
      expect(review.height, 40);
      expect(card.right - review.right, 25);
      expect(card.bottom - review.bottom, closeTo(25, 0.01));
    }
  });

  testWidgets('ReviewMenu property offers only the reviews that are due', (
    tester,
  ) async {
    useDesktopSurface(tester);
    for (final due in examplesOf(_generatedSummary, runs: 16)) {
      await tester.pumpWidget(hostedInLightTheme(_Reviews().section(due)));

      final button = _reviewButton(tester);

      expect(button.label, _reviewLabel(due));
      expect(button.variant, ButtonVariant.primary);
      expect(button.icon, DesignIcons.study);
      expect(button.onPressed != null, due.reviewableCount > 0);

      if (due.reviewableCount == 0) {
        continue;
      }

      await tester.tap(find.text(_reviewLabel(due)));
      await tester.pumpAndSettle();

      final review = tester.getRect(find.byType(DesignButton));
      final panel = tester.getRect(find.byType(DropdownPanel));

      expect(panel.top - review.bottom, closeTo(8, 0.01));
      expect(panel.right, closeTo(review.right, 0.01));
      expect(
        find.text('Flashcards'),
        due.flashcards.due > 0 ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Test'),
        due.testItems.due > 0 ? findsOneWidget : findsNothing,
      );

      for (final count in [due.flashcards.due, due.testItems.due]) {
        if (count > 0) {
          expect(find.text('$count due'), findsWidgets);
        }
      }
    }
  });

  testWidgets('DueSection property starts the chosen review', (tester) async {
    useDesktopSurface(tester);
    for (final choice in examplesOf(
      (random) => oneOf(random, ['Flashcards', 'Test']),
      runs: 4,
    )) {
      const due = DueSummary(
        flashcards: StudyCount(due: 2, done: 0),
        testItems: StudyCount(due: 4, done: 1),
        notes: StudyCount.nothing,
      );
      final reviews = _Reviews();

      await tester.pumpWidget(hostedInLightTheme(reviews.section(due)));
      await tester.tap(find.text(_reviewLabel(due)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(choice));
      await tester.pumpAndSettle();

      expect(reviews.started, [choice == 'Flashcards' ? 'flashcards' : 'test']);
      expect(find.byType(DropdownPanel), findsNothing);
    }
  });
}
