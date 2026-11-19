import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/assessment/add_answer_button.dart';
import 'package:leffic/features/assessment/answer_fieldset.dart';
import 'package:leffic/features/assessment/answer_row.dart';
import 'package:leffic/shared/design/choice_marks.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_shadows.dart';
import 'package:leffic/shared/design/icons/design_icon.dart';
import 'package:leffic/shared/design/surface_box.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const double _rowHeight = 48;
const double _rowStart = 16;
const double _rowEnd = 8;
const double _rowGap = 12;
const double _fieldHeight = 44;
const double _removeSide = 32;
const double _addHeight = 44;
const double _legendGap = 8;

typedef _FieldsetCalls = List<String>;
typedef _FieldsetExample = ({
  Brightness brightness,
  List<String> answers,
  int correctIndex,
});

_FieldsetExample _fieldsetExampleOf(Random random) {
  final count = integerBetween(random, 1, 6);

  return (
    brightness: oneOf(random, Brightness.values),
    answers: [for (var index = 0; index < count; index++) wordOf(random)],
    correctIndex: integerBetween(random, 0, count - 1),
  );
}

Widget _fieldsetOf(_FieldsetExample example, _FieldsetCalls calls) {
  final controllers = [
    for (final answer in example.answers) TextEditingController(text: answer),
  ];

  return hostedInTheme(
    Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 550,
        child: AnswerFieldset(
          answers: controllers,
          correctIndex: example.correctIndex,
          onMarkCorrect: (index) => calls.add('correct $index'),
          onRemove: (index) => calls.add('remove $index'),
          onAdd: () => calls.add('add'),
          onChanged: () => calls.add('changed'),
        ),
      ),
    ),
    brightness: example.brightness,
  );
}

Finder _inRow(int index, Finder matching) {
  return find.descendant(
    of: find.byType(AnswerRow).at(index),
    matching: matching,
  );
}

SurfaceLook _listLook(WidgetTester tester) {
  return tester
      .widget<SurfaceBox>(
        find
            .descendant(
              of: find.byType(AnswerFieldset),
              matching: find.byType(SurfaceBox),
            )
            .first,
      )
      .look;
}

void main() {
  testWidgets('AnswerFieldset property lays out the .answers fieldset', (
    tester,
  ) async {
    for (final example in examplesOf(_fieldsetExampleOf, runs: 8)) {
      await tester.pumpWidget(_fieldsetOf(example, []));

      final colors = DesignColors.forBrightness(example.brightness);
      final shadows = DesignShadows.forBrightness(example.brightness);
      final legend = tester.getRect(find.text('Answers'));
      final hint = tester.getRect(find.text('Pick the correct one'));
      final rows = find.byType(AnswerRow);
      final firstRow = tester.getRect(rows.first);
      final lastRow = tester.getRect(rows.last);
      final add = tester.getRect(find.byType(AddAnswerButton));
      final listLook = _listLook(tester);

      expect(renderedStyleOf(tester, 'Answers').fontWeight, FontWeight.w500);
      expect(renderedStyleOf(tester, 'Answers').fontSize, 14);
      expect(
        renderedStyleOf(tester, 'Pick the correct one').color,
        colors.inkTertiary,
      );
      expect(hint.left, legend.right + _legendGap);
      expect(firstRow.top, legend.bottom + _legendGap + 1);
      expect(listLook.border, BorderSide(color: colors.lineStrong));
      expect(listLook.fill, colors.surface);
      expect(listLook.shadows, shadows.raised);
      expect(add.top, lastRow.bottom);
      expect(add.height, _addHeight);

      for (var index = 0; index < example.answers.length; index++) {
        final row = tester.getRect(rows.at(index));
        final radio = tester.getRect(
          _inRow(index, find.byType(DesignRadio<int>)),
        );
        final field = tester.getRect(_inRow(index, find.byType(TextField)));
        final remove = tester.getRect(
          _inRow(index, find.byType(AnswerRemoveButton)),
        );

        expect(row.height, _rowHeight);
        expect(radio.left, row.left + _rowStart);
        expect(radio.center.dy, row.top + (_rowHeight - 1) / 2);
        expect(field.left, radio.right + _rowGap);
        expect(field.height, _fieldHeight);
        expect(remove.size, const Size(_removeSide, _removeSide));
        expect(remove.right, row.right - _rowEnd);
      }
    }
  });

  testWidgets('AnswerFieldset property tags and tints only the correct row', (
    tester,
  ) async {
    for (final example in examplesOf(_fieldsetExampleOf, runs: 8)) {
      await tester.pumpWidget(_fieldsetOf(example, []));

      final colors = DesignColors.forBrightness(example.brightness);
      final tag = find.text('Correct');
      final correctRow = find.byType(AnswerRow).at(example.correctIndex);

      expect(tag, findsOneWidget);
      expect(find.descendant(of: correctRow, matching: tag), findsOneWidget);
      expect(renderedStyleOf(tester, 'Correct').fontSize, 12);
      expect(renderedStyleOf(tester, 'Correct').fontWeight, FontWeight.w600);
      expect(renderedStyleOf(tester, 'Correct').color, colors.brandStrong);
      expect(
        tester.getRect(tag).right,
        tester
                .getRect(
                  _inRow(example.correctIndex, find.byType(AnswerRemoveButton)),
                )
                .left -
            _rowGap,
      );

      for (var index = 0; index < example.answers.length; index++) {
        final row = tester.widget<AnswerRow>(find.byType(AnswerRow).at(index));

        expect(row.isCorrect, index == example.correctIndex);
        expect(
          answerRowFillOf(isCorrect: row.isCorrect, colors: colors),
          row.isCorrect ? colors.brandSurface : null,
        );
      }
    }
  });

  testWidgets('AnswerFieldset property reports every edit it offers', (
    tester,
  ) async {
    for (final example in examplesOf(_fieldsetExampleOf, runs: 6)) {
      final calls = <String>[];
      final target = example.answers.length - 1;

      await tester.pumpWidget(_fieldsetOf(example, calls));
      await tester.tap(_inRow(target, find.byType(DesignRadio<int>)));
      await tester.tap(find.bySemanticsLabel('Remove answer ${target + 1}'));
      await tester.tap(find.text('Add answer'));
      await tester.enterText(_inRow(target, find.byType(TextField)), 'typed');

      final expectedCalls = [
        if (target != example.correctIndex) 'correct $target',
        'remove $target',
        'add',
        'changed',
      ];

      expect(calls, expectedCalls);
    }
  });

  testWidgets('AnswerRow property edges the focused row in brand', (
    tester,
  ) async {
    for (final example in examplesOf(_fieldsetExampleOf, runs: 4)) {
      await tester.pumpWidget(_fieldsetOf(example, []));

      final colors = DesignColors.forBrightness(example.brightness);
      final target = example.answers.length - 1;

      expect(find.byType(FocusEdge), findsNothing);

      await tester.tap(_inRow(target, find.byType(TextField)));
      await tester.pump();

      final edge = tester.widget<FocusEdge>(find.byType(FocusEdge));
      final edgeRect = tester.getRect(find.byType(FocusEdge));
      final row = tester.getRect(find.byType(AnswerRow).at(target));

      expect(
        find.descendant(
          of: find.byType(AnswerRow).at(target),
          matching: find.byType(FocusEdge),
        ),
        findsOneWidget,
      );
      expect(edge.color, colors.brand);
      expect(edgeRect.width, 2);
      expect(edgeRect.left, row.left);
    }
  });

  testWidgets('AnswerRemoveButton property turns danger under the pointer', (
    tester,
  ) async {
    for (final example in examplesOf(_fieldsetExampleOf, runs: 4)) {
      await tester.pumpWidget(_fieldsetOf(example, []));

      final colors = DesignColors.forBrightness(example.brightness);
      final remove = find.byType(AnswerRemoveButton).first;
      final icon = find.descendant(
        of: remove,
        matching: find.byType(DesignIcon),
      );

      expect(tester.widget<DesignIcon>(icon).color, colors.inkTertiary);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);

      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(remove));
      await tester.pumpAndSettle();

      final fill = tester.widget<SurfaceBox>(
        find.descendant(of: remove, matching: find.byType(SurfaceBox)),
      );

      expect(tester.widget<DesignIcon>(icon).color, colors.danger);
      expect(fill.look.fill, colors.dangerSurface);
      expect(fill.borderRadius, 8);

      await mouse.removePointer();
    }
  });

  testWidgets('AddAnswerButton property is the brand .answer-add row', (
    tester,
  ) async {
    for (final example in examplesOf(_fieldsetExampleOf, runs: 4)) {
      await tester.pumpWidget(_fieldsetOf(example, []));

      final colors = DesignColors.forBrightness(example.brightness);
      final add = tester.getRect(find.byType(AddAnswerButton));
      final icon = tester.getRect(
        find.descendant(
          of: find.byType(AddAnswerButton),
          matching: find.byType(DesignIcon),
        ),
      );
      final label = tester.getRect(find.text('Add answer'));

      expect(icon.left, add.left + _rowStart);
      expect(icon.size, const Size(18, 18));
      expect(label.left, icon.right + _rowGap);
      expect(icon.center.dy, add.center.dy);
      expect(renderedStyleOf(tester, 'Add answer').color, colors.brand);
      expect(renderedStyleOf(tester, 'Add answer').fontSize, 14);
      expect(renderedStyleOf(tester, 'Add answer').fontWeight, FontWeight.w500);
    }
  });
}
