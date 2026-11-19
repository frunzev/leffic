import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_text_field.dart';
import 'package:leffic/shared/design/input_frame.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/system_fonts.dart';

const double _chromeTextAreaBaseline = 31;
const double _chromeTextFieldBaseline = 26;
const double _chromeBaselineSnap = 0.5;

typedef _InputExample = ({String text, String? placeholder});

List<_InputExample> _inputExamples() {
  return examplesOf(
    (random) => (
      text: oneOf(random, ['', 'Hg ${wordOf(random)}']),
      placeholder: oneOf(random, [null, 'Ask ${wordOf(random)}']),
    ),
    runs: 8,
  );
}

double _firstBaselineInFrame(WidgetTester tester) {
  final frameTop = tester.getTopLeft(find.byType(InputFrame)).dy;
  final editable = tester.allRenderObjects.whereType<RenderEditable>().single;
  final editableTop = editable.localToGlobal(Offset.zero).dy;
  final baseline = editable.computeDistanceToActualBaseline(
    TextBaseline.alphabetic,
  );

  return editableTop + baseline - frameTop;
}

void main() {
  testWidgets('DesignTextArea property sets its first line like textarea', (
    tester,
  ) async {
    await tester.runAsync(loadSystemFonts);

    for (final example in _inputExamples()) {
      await tester.pumpWidget(
        hostedInLightTheme(
          Center(
            child: SizedBox(
              width: 400,
              child: DesignTextArea(
                controller: TextEditingController(text: example.text),
                placeholder: example.placeholder,
              ),
            ),
          ),
        ),
      );

      expect(
        _firstBaselineInFrame(tester),
        closeTo(_chromeTextAreaBaseline, _chromeBaselineSnap),
      );
    }
  });

  testWidgets('DesignTextField property sets its text like .input', (
    tester,
  ) async {
    await tester.runAsync(loadSystemFonts);

    for (final example in _inputExamples()) {
      await tester.pumpWidget(
        hostedInLightTheme(
          Center(
            child: SizedBox(
              width: 400,
              child: DesignTextField(
                controller: TextEditingController(text: example.text),
                placeholder: example.placeholder,
              ),
            ),
          ),
        ),
      );

      expect(
        _firstBaselineInFrame(tester),
        closeTo(_chromeTextFieldBaseline, _chromeBaselineSnap),
      );
    }
  });
}
