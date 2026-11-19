import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/segmented_control.dart';
import 'package:leffic/shared/settings/chat_engine_choice.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

String _labelOf(String choice) => choice;

Widget _control({
  required List<String> choices,
  required String selected,
  required ValueChanged<String> onSelected,
  required SegmentedSize size,
}) {
  return SegmentedControl<String>(
    choices: choices,
    labelOf: _labelOf,
    selected: selected,
    onSelected: onSelected,
    size: size,
  );
}

List<String> _distinctChoices(List<String> words) => words.toSet().toList();

void main() {
  testWidgets('SegmentedControl property marks only the chosen engine', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final engine in examplesOf(
      (random) => oneOf(random, ChatEngineChoice.values),
      runs: 6,
    )) {
      await tester.pumpWidget(
        hostedPlainly(
          Center(
            child: SegmentedControl<ChatEngineChoice>(
              choices: ChatEngineChoice.values,
              labelOf: (choice) => choice.label,
              selected: engine,
              onSelected: (choice) {},
            ),
          ),
        ),
      );

      for (final choice in ChatEngineChoice.values) {
        final style = renderedStyleOf(tester, choice.label);
        final isChosen = choice == engine;

        expect(style.fontSize, 14);
        expect(style.fontWeight, isChosen ? FontWeight.w600 : FontWeight.w400);
        expect(style.color, isChosen ? colors.ink : colors.inkSecondary);
      }
    }
  });

  testWidgets('SegmentedControl property reports another choice only', (
    tester,
  ) async {
    for (final (selected, tapped) in examplesOf(
      (random) => (
        oneOf(random, ChatEngineChoice.values),
        oneOf(random, ChatEngineChoice.values),
      ),
    )) {
      final chosen = <ChatEngineChoice>[];

      await tester.pumpWidget(
        hostedPlainly(
          Center(
            child: SegmentedControl<ChatEngineChoice>(
              choices: ChatEngineChoice.values,
              labelOf: (choice) => choice.label,
              selected: selected,
              onSelected: chosen.add,
            ),
          ),
        ),
      );
      await tester.tap(find.text(tapped.label));

      expect(chosen, [if (tapped != selected) tapped]);
    }
  });

  testWidgets('SegmentedControl property spaces segments like .segmented', (
    tester,
  ) async {
    for (final words in examplesOf(
      (random) => [
        for (var index = 0; index < integerBetween(random, 2, 4); index++)
          wordOf(random, maximum: 8),
      ],
      runs: 10,
    )) {
      final choices = _distinctChoices(words);

      await tester.pumpWidget(
        hostedPlainly(
          Center(
            child: _control(
              choices: choices,
              selected: choices.first,
              onSelected: (choice) {},
              size: SegmentedSize.regular,
            ),
          ),
        ),
      );

      final control = tester.getRect(find.byType(SegmentedControl<String>));
      final faces = [
        for (final choice in choices)
          tester.getRect(
            find
                .ancestor(
                  of: find.text(choice),
                  matching: find.byType(SegmentFace),
                )
                .first,
          ),
      ];

      expect(control.height, 38);
      expect(faces.first.left - control.left, 3);
      expect(faces.first.top - control.top, 3);
      expect(control.right - faces.last.right, 3);

      for (var index = 1; index < faces.length; index++) {
        expect(faces[index].left - faces[index - 1].right, 2);
      }

      for (final face in faces) {
        expect(face.height, 32);
        expect(face.width, greaterThanOrEqualTo(44));
      }
    }
  });

  testWidgets('SegmentedControl property splits the large width evenly', (
    tester,
  ) async {
    for (final (width, count) in examplesOf(
      (random) => (
        integerBetween(random, 240, 780).toDouble(),
        integerBetween(random, 2, 4),
      ),
      runs: 10,
    )) {
      final choices = [for (var index = 0; index < count; index++) 'C$index'];

      await tester.pumpWidget(
        hostedPlainly(
          Center(
            child: SizedBox(
              width: width,
              child: _control(
                choices: choices,
                selected: choices.last,
                onSelected: (choice) {},
                size: SegmentedSize.large,
              ),
            ),
          ),
        ),
      );

      final control = tester.getRect(find.byType(SegmentedControl<String>));
      final faceWidth = (width - 6 - 2 * (count - 1)) / count;

      expect(control.size, Size(width, 42));

      for (final choice in choices) {
        final face = tester.getRect(
          find
              .ancestor(
                of: find.text(choice),
                matching: find.byType(SegmentFace),
              )
              .first,
        );

        expect(face.width, closeTo(faceWidth, 1e-6));
        expect(face.height, 36);
        expect(renderedStyleOf(tester, choice).fontSize, 16);
      }
    }
  });
}
