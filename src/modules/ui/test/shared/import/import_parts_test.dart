import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/segmented_control.dart';
import 'package:leffic/shared/design/spinner.dart';
import 'package:leffic/shared/import/check_label.dart';
import 'package:leffic/shared/import/footer_hint.dart';
import 'package:leffic/shared/import/generation_choices.dart';
import 'package:leffic/shared/import/import_buttons.dart';
import 'package:leffic/shared/import/import_plan.dart';
import 'package:leffic/shared/import/import_source.dart';
import 'package:leffic/shared/import/reading_source_notice.dart';
import 'package:leffic/shared/import/review_step.dart';
import 'package:leffic/shared/import/source_step.dart';
import 'package:leffic/shared/import/source_text_panel.dart';
import 'package:leffic/shared/import/unit_choice.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';
import 'import_fakes.dart';

const double _bodyWidth = 550;
const Key _panelKey = Key('panel');

Widget _sized(Widget child) {
  return hostedPlainly(
    Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: _bodyWidth, child: child),
    ),
  );
}

bool _isEnabled(WidgetTester tester) {
  return tester.widget<DesignButton>(find.byType(DesignButton)).onPressed !=
      null;
}

void main() {
  testWidgets('GenerateButton property hands over exactly its plan', (
    tester,
  ) async {
    for (final source in examplesOf(generatedSource, runs: 6)) {
      final finished = <ImportPlan>[];
      final plan = GenerationPlan(
        source: source,
        text: source.label,
        choices: GenerationChoices.starting,
      );

      await tester.pumpWidget(
        _sized(GenerateButton(plan: null, onFinish: finished.add)),
      );

      expect(_isEnabled(tester), isFalse);

      await tester.pumpWidget(
        _sized(GenerateButton(plan: plan, onFinish: finished.add)),
      );
      await tester.tap(find.text('Generate'));

      expect(finished, [plan]);
    }
  });

  testWidgets('ContinueButton property reads exactly its source', (
    tester,
  ) async {
    for (final source in examplesOf(generatedSource, runs: 6)) {
      final read = <ImportSource>[];

      await tester.pumpWidget(
        _sized(ContinueButton(readySource: null, onRead: read.add)),
      );

      expect(_isEnabled(tester), isFalse);

      await tester.pumpWidget(
        _sized(ContinueButton(readySource: source, onRead: read.add)),
      );
      await tester.tap(find.text('Continue'));

      expect(read, [source]);
    }
  });

  testWidgets('FooterHint property takes the free space left of buttons', (
    tester,
  ) async {
    for (final hint in examplesOf(wordOf, runs: 4)) {
      final colors = DesignColors.forBrightness(Brightness.light);

      await tester.pumpWidget(
        _sized(
          Row(
            children: [
              FooterHint(text: hint),
              const SizedBox(key: _panelKey, width: 80, height: 40),
            ],
          ),
        ),
      );

      final hintRect = tester.getRect(find.byType(FooterHint));

      expect(hintRect.left, 0);
      expect(hintRect.right, tester.getRect(find.byKey(_panelKey)).left);
      expect(renderedStyleOf(tester, hint).fontSize, 14);
      expect(renderedStyleOf(tester, hint).color, colors.inkTertiary);
    }
  });

  testWidgets('ReadingSourceNotice property names the source being read', (
    tester,
  ) async {
    for (final label in examplesOf(wordOf, runs: 4)) {
      await tester.pumpWidget(
        _sized(ReadingSourceNotice(key: UniqueKey(), sourceLabel: label)),
      );

      final notice = tester.getRect(find.byType(ReadingSourceNotice));
      final spinner = tester.getRect(find.byType(Spinner));

      expect(find.text('Reading $label…'), findsOneWidget);
      expect(spinner.top - notice.top, 64);
      expect(spinner.size, const Size(32, 32));
    }
  });

  testWidgets('ReviewStep property shows where the text came from', (
    tester,
  ) async {
    for (final (label, edited) in examplesOf(
      (random) => (wordOf(random), 'Edited ${wordOf(random)}'),
      runs: 4,
    )) {
      final edits = <String>[];

      useDesktopSurface(tester);
      await tester.pumpWidget(
        _sized(
          ReviewStep(
            key: UniqueKey(),
            sourceLabel: label,
            controller: TextEditingController(),
            onTyped: edits.add,
            choices: GenerationChoices.starting,
            onChoicesChanged: (choices) {},
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), edited);

      final from = tester.getRect(find.byType(ReviewSourceLine));
      final fieldLabel = tester.getRect(find.text('Extracted text'));

      expect(find.text('From $label'), findsOneWidget);
      expect(fieldLabel.top - from.bottom, 16);
      expect(edits, [edited]);
    }
  });

  testWidgets('SourceTextPanel property shows its copy and reports typing', (
    tester,
  ) async {
    for (final (copy, typed) in examplesOf(
      (random) =>
          (oneOf(random, [linkFieldCopy, topicFieldCopy]), wordOf(random)),
      runs: 4,
    )) {
      final typedTexts = <String>[];

      await tester.pumpWidget(
        _sized(
          SourceTextPanel(
            key: UniqueKey(),
            copy: copy,
            controller: TextEditingController(),
            onChanged: typedTexts.add,
          ),
        ),
      );

      expect(find.text(copy.label), findsOneWidget);
      expect(find.text(copy.hint), findsOneWidget);
      expect(find.text(copy.placeholder), findsOneWidget);

      await tester.enterText(find.byType(TextField), typed);

      expect(typedTexts, [typed]);
    }
  });

  testWidgets('SourceStep property gaps every panel but pasted text', (
    tester,
  ) async {
    for (final kind in examplesOf(
      (random) => oneOf(random, ImportSourceKind.values),
      runs: 8,
    )) {
      final selected = <ImportSourceKind>[];

      await tester.pumpWidget(
        _sized(
          SourceStep(
            kind: kind,
            onKindSelected: selected.add,
            panel: const SizedBox(key: _panelKey, height: 40),
          ),
        ),
      );

      final segmented = find.byType(SegmentedControl<ImportSourceKind>);
      final gap =
          tester.getRect(find.byKey(_panelKey)).top -
          tester.getRect(segmented).bottom;

      expect(gap, kind == ImportSourceKind.text ? 0 : 16);
    }
  });

  testWidgets('CheckLabel property toggles once from the box or the words', (
    tester,
  ) async {
    for (final (label, isChecked) in examplesOf(
      (random) => (wordOf(random), random.nextBool()),
      runs: 4,
    )) {
      final toggles = <String>[];

      await tester.pumpWidget(
        _sized(
          CheckLabel(
            label: label,
            isChecked: isChecked,
            onToggle: () => toggles.add(label),
          ),
        ),
      );
      await tester.tap(find.text(label));
      await tester.tap(find.byType(TappableLabel), warnIfMissed: false);

      expect(toggles, [label, label]);
    }
  });

  testWidgets('UnitChoice property shows its options only when chosen', (
    tester,
  ) async {
    for (final isChosen in examplesOf((random) => random.nextBool(), runs: 4)) {
      final toggles = <bool>[];

      await tester.pumpWidget(
        _sized(
          UnitChoice(
            name: 'Note',
            hint: 'Read it through once',
            isChosen: isChosen,
            onToggle: () => toggles.add(isChosen),
            chosenOptions: const [SizedBox(key: _panelKey, height: 10)],
          ),
        ),
      );
      await tester.tap(find.text('Note'));

      expect(find.byKey(_panelKey), isChosen ? findsOneWidget : findsNothing);
      expect(toggles, [isChosen]);
    }
  });
}
