import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/import/check_label.dart';
import 'package:leffic/shared/import/generation_choices.dart';
import 'package:leffic/shared/import/generation_choices_section.dart';
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

Future<void> _pumpSection(
  WidgetTester tester,
  GenerationChoices choices,
  List<GenerationChoices> changes,
) async {
  useDesktopSurface(tester);
  await tester.pumpWidget(_section(choices, changes));
}

Widget _section(GenerationChoices choices, List<GenerationChoices> changes) {
  return _sized(
    GenerationChoicesSection(choices: choices, onChanged: changes.add),
  );
}

void main() {
  testWidgets('GenerationChoicesSection property spaces like the CSS', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    await _pumpSection(tester, GenerationChoices.starting, []);

    final section = tester.getRect(find.byType(GenerationChoicesSection));
    final heading = tester.getRect(find.text('Generate'));
    final flashcards = tester.getRect(find.byType(UnitChoice).at(0));
    final test = tester.getRect(find.byType(UnitChoice).at(1));
    final note = tester.getRect(find.byType(UnitChoice).at(2));
    final headingStyle = renderedStyleOf(tester, 'Generate');

    expect(heading.top - section.top, 24);
    expect(flashcards.top - heading.bottom, 12);
    expect(test.top - flashcards.bottom, 16);
    expect(note.top - test.bottom, 16);
    expect(headingStyle.fontSize, 14);
    expect(headingStyle.fontWeight, FontWeight.w600);
    expect(headingStyle.color, colors.inkSecondary);
  });

  testWidgets('GenerationChoicesSection property indents options by 42', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    await _pumpSection(tester, GenerationChoices.starting, []);

    final section = tester.getRect(find.byType(GenerationChoicesSection));
    final optionLabel = find.text('Types and how many').first;
    final labelRect = tester.getRect(optionLabel);
    final head = tester.getRect(find.byType(TappableLabel).first);
    final firstRow = tester.getRect(find.byType(TypeRow).first);
    final labelStyle = renderedStyleOf(tester, 'Recall one fact at a time');

    expect(labelRect.left - section.left, 42);
    expect(labelRect.top - head.bottom, 12);
    expect(firstRow.top - labelRect.bottom, 8);
    expect(renderedStyleOf(tester, 'Flashcards').fontSize, 16);
    expect(renderedStyleOf(tester, 'Flashcards').fontWeight, FontWeight.w600);
    expect(labelStyle.fontSize, 14);
    expect(labelStyle.color, colors.inkTertiary);
  });

  testWidgets('GenerationChoicesSection property toggles what is generated', (
    tester,
  ) async {
    for (final choices in examplesOf(generatedChoices, runs: 6)) {
      final changes = <GenerationChoices>[];

      await _pumpSection(tester, choices, changes);

      for (final name in ['Flashcards', 'Test', 'Note']) {
        await tester.tap(find.text(name));
      }

      expect(changes[0].flashcards.isChosen, !choices.flashcards.isChosen);
      expect(changes[1].test.isChosen, !choices.test.isChosen);
      expect(changes[2].isNoteChosen, !choices.isNoteChosen);
      expect(
        find.byType(TypeRow),
        findsNWidgets(
          (choices.flashcards.isChosen ? 4 : 0) +
              (choices.test.isChosen ? 3 : 0),
        ),
      );
    }
  });
}
