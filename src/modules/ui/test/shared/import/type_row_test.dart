import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/choice_marks.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/hint_tip.dart';
import 'package:leffic/shared/design/segmented_control.dart';
import 'package:leffic/shared/import/amount_choice.dart';
import 'package:leffic/shared/import/custom_amount_field.dart';
import 'package:leffic/shared/import/generation_choices.dart';
import 'package:leffic/shared/import/type_row.dart';
import 'package:leffic/shared/import/unit_choice.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';
import 'import_fakes.dart';

const double _sectionWidth = 550;

Widget _sized(Widget child) {
  return hostedPlainly(
    Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: _sectionWidth, child: child),
    ),
  );
}

AmountMode _otherMode(AmountMode mode) {
  final otherModes = [
    for (final candidate in AmountMode.values)
      if (candidate != mode) candidate,
  ];

  return otherModes.first;
}

void main() {
  testWidgets('TypeRow property offers amounts for chosen types only', (
    tester,
  ) async {
    for (final (choice, option) in examplesOf(
      (random) => (
        generatedSetChoice(random, flashcardTypeOptions),
        oneOf(random, flashcardTypeOptions),
      ),
      runs: 10,
    )) {
      final changes = <GeneratedSetChoice>[];
      final isTypeChosen = choice.chosenTypeIds.contains(option.id);
      final isCustomShown =
          isTypeChosen &&
          choice.amountChoiceOf(option.id).mode == AmountMode.custom;

      await tester.pumpWidget(
        _sized(
          TypeRow(
            key: UniqueKey(),
            option: option,
            choice: choice,
            onChanged: changes.add,
          ),
        ),
      );

      expect(
        find.byType(SegmentedControl<AmountMode>),
        isTypeChosen ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(CustomAmountField),
        isCustomShown ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(HintTip),
        option.explanation == null ? findsNothing : findsOneWidget,
      );

      await tester.tap(find.text(option.label));

      expect(changes.single.chosenTypeIds.contains(option.id), !isTypeChosen);
    }
  });

  testWidgets('TypeRow property lays out the name column like the CSS', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);
    final choice = GenerationChoices.starting.flashcards;
    final option = flashcardTypeOptions.first;

    await tester.pumpWidget(
      _sized(TypeRow(option: option, choice: choice, onChanged: (value) {})),
    );

    final row = tester.getRect(find.byType(TypeRow));
    final checkbox = tester.getRect(find.byType(DesignCheckbox));
    final label = tester.getRect(find.text(option.label));
    final segmented = tester.getRect(find.byType(SegmentedControl<AmountMode>));

    expect(row.height, 38);
    expect(checkbox.size, const Size(18, 18));
    expect(label.left - checkbox.right, 8);
    expect(segmented.left - row.left, 176 + 16);
    expect(segmented.height, 38);
    expect(checkbox.center.dy, closeTo(row.center.dy, 0.01));
    expect(renderedStyleOf(tester, option.label).fontSize, 14);
    expect(renderedStyleOf(tester, option.label).color, colors.ink);
  });

  testWidgets('TypeRow property is 32 tall for a type that is not chosen', (
    tester,
  ) async {
    final oneLineOptions = [
      for (final option in flashcardTypeOptions)
        if (option.id != 'cloze') option,
    ];

    for (final option in examplesOf(
      (random) => oneOf(random, oneLineOptions),
      runs: 3,
    )) {
      final choice = GenerationChoices.starting.flashcards.withTypeToggled(
        option.id,
      );
      final unchosen = choice.chosenTypeIds.contains(option.id)
          ? choice.withTypeToggled(option.id)
          : choice;

      await tester.pumpWidget(
        _sized(
          TypeRow(
            key: UniqueKey(),
            option: option,
            choice: unchosen,
            onChanged: (value) {},
          ),
        ),
      );

      expect(tester.getSize(find.byType(TypeRow)).height, 32);
    }
  });

  testWidgets('TypeRow property sets the amount mode and custom amount', (
    tester,
  ) async {
    for (final (mode, typed) in examplesOf(
      (random) =>
          (oneOf(random, AmountMode.values), integerBetween(random, 1, 90)),
      runs: 6,
    )) {
      final changes = <GeneratedSetChoice>[];
      final option = testTypeOptions.first;
      final choice = GenerationChoices.starting.test.withAmountChoice(
        typeId: option.id,
        amountChoice: AmountChoice.automatic.withMode(AmountMode.custom),
      );

      await tester.pumpWidget(
        _sized(
          TypeRow(
            key: UniqueKey(),
            option: option,
            choice: choice,
            onChanged: changes.add,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '$typed');
      await tester.tap(find.text(mode.label));

      expect(changes.first.amountChoiceOf(option.id).amount, typed);
      expect(changes.first.amountChoiceOf(option.id).mode, AmountMode.custom);

      if (mode != AmountMode.custom) {
        expect(changes.last.amountChoiceOf(option.id).mode, mode);
      }
    }
  });

  testWidgets('TypeRow property changes the amount of its own type only', (
    tester,
  ) async {
    for (final (choice, option, mode) in examplesOf(
      (random) => (
        generatedSetChoice(random, flashcardTypeOptions),
        oneOf(random, flashcardTypeOptions),
        oneOf(random, AmountMode.values),
      ),
      runs: 10,
    )) {
      final changes = <GeneratedSetChoice>[];
      final chosen = choice.chosenTypeIds.contains(option.id)
          ? choice
          : choice.withTypeToggled(option.id);
      final shown = chosen.withAmountChoice(
        typeId: option.id,
        amountChoice: AmountChoice.automatic.withMode(_otherMode(mode)),
      );

      await tester.pumpWidget(
        _sized(
          TypeRow(
            key: UniqueKey(),
            option: option,
            choice: shown,
            onChanged: changes.add,
          ),
        ),
      );
      await tester.tap(find.text(mode.label));

      final changed = changes.single;

      expect(changed.amountChoiceOf(option.id).mode, mode);

      for (final otherOption in flashcardTypeOptions) {
        if (otherOption.id != option.id) {
          expect(
            changed.amountChoiceOf(otherOption.id),
            shown.amountChoiceOf(otherOption.id),
          );
        }
      }
    }
  });

  testWidgets('TypeChoiceOptions property shows every type its own amount', (
    tester,
  ) async {
    for (final choice in examplesOf(
      (random) => generatedSetChoice(random, flashcardTypeOptions),
      runs: 10,
    )) {
      await tester.pumpWidget(
        _sized(
          TypeChoiceOptions(
            key: UniqueKey(),
            options: flashcardTypeOptions,
            choice: choice,
            onChanged: (value) {},
          ),
        ),
      );

      for (final option in flashcardTypeOptions) {
        final row = find.ancestor(
          of: find.text(option.label),
          matching: find.byType(TypeRow),
        );
        final segmented = find.descendant(
          of: row,
          matching: find.byType(SegmentedControl<AmountMode>),
        );
        final customField = find.descendant(
          of: row,
          matching: find.byType(CustomAmountField),
        );
        final amountChoice = choice.amountChoiceOf(option.id);
        final isTypeChosen = choice.chosenTypeIds.contains(option.id);
        final isCustomShown =
            isTypeChosen && amountChoice.mode == AmountMode.custom;

        expect(segmented, isTypeChosen ? findsOneWidget : findsNothing);
        expect(customField, isCustomShown ? findsOneWidget : findsNothing);

        if (isTypeChosen) {
          expect(
            tester.widget<SegmentedControl<AmountMode>>(segmented).selected,
            amountChoice.mode,
          );
        }

        if (isCustomShown) {
          expect(
            tester.widget<CustomAmountField>(customField).amount,
            amountChoice.customAmount,
          );
        }
      }
    }
  });
}
