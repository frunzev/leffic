import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_shadows.dart';
import 'package:leffic/shared/design/design_text_field.dart';
import 'package:leffic/shared/design/input_frame.dart';
import 'package:leffic/shared/design/pressable.dart';
import 'package:leffic/shared/design/surface_box.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

const double _fieldWidth = 320;

InteractionState _inputStateOf(Random random) {
  return InteractionState(
    isEnabled: true,
    isHovered: random.nextBool(),
    isPressed: false,
    isFocused: random.nextBool(),
  );
}

Widget _sized(Widget field) {
  return hostedPlainly(
    Center(
      child: SizedBox(width: _fieldWidth, child: field),
    ),
  );
}

SurfaceLook _shownLook(WidgetTester tester) {
  return tester.widget<SurfaceBox>(find.byType(SurfaceBox)).look;
}

const Map<TextFieldSize, double> _cssHeights = {
  TextFieldSize.small: 32,
  TextFieldSize.regular: 40,
  TextFieldSize.large: 44,
};
const Map<TextFieldSize, double> _cssTextInsets = {
  TextFieldSize.small: 13,
  TextFieldSize.regular: 13,
  TextFieldSize.large: 17,
};

void main() {
  test('inputLookOf property matches app-forms.css in every state', () {
    forAll(
      (random) => (
        _inputStateOf(random),
        oneOf(random, FieldValidity.values),
        oneOf(random, Brightness.values),
      ),
      (example) {
        final (state, validity, brightness) = example;
        final colors = DesignColors.forBrightness(brightness);
        final shadows = DesignShadows.forBrightness(brightness);
        final look = inputLookOf(
          state: state,
          validity: validity,
          colors: colors,
          shadows: shadows,
        );
        final expectedBorder = validity == FieldValidity.invalid
            ? colors.danger
            : state.isFocused
            ? colors.brand
            : state.isHovered
            ? colors.lineHover
            : colors.lineStrong;

        expect(look.fill, colors.surface);
        expect(look.border, BorderSide(color: expectedBorder));
        expect(
          look.shadows,
          state.isFocused ? shadows.focusRing : shadows.raised,
        );
        expect(
          look.edgeHighlight,
          state.isFocused ? const Color(0x00000000) : shadows.edgeHighlight,
        );
      },
    );
  });

  testWidgets('DesignTextField property is as tall as .input and .input-lg', (
    tester,
  ) async {
    for (final (size, placeholder) in examplesOf(
      (random) => (oneOf(random, TextFieldSize.values), wordOf(random)),
      runs: 8,
    )) {
      await tester.pumpWidget(
        _sized(
          DesignTextField(
            key: UniqueKey(),
            controller: TextEditingController(),
            placeholder: placeholder,
            size: size,
          ),
        ),
      );

      final field = tester.getRect(find.byType(DesignTextField));
      final hint = tester.getRect(find.text(placeholder));
      final expectedHeight = _cssHeights[size]!;
      final expectedInset = _cssTextInsets[size]!;

      expect(field.size, Size(_fieldWidth, expectedHeight));
      expect(hint.left - field.left, expectedInset);
      expect(hint.center.dy, closeTo(field.center.dy, 0.5));
    }
  });

  testWidgets('DesignTextField property reports typing and focus', (
    tester,
  ) async {
    for (final typed in examplesOf(wordOf, runs: 5)) {
      final changes = <String>[];

      await tester.pumpWidget(
        _sized(
          DesignTextField(
            key: UniqueKey(),
            controller: TextEditingController(),
            onChanged: changes.add,
          ),
        ),
      );

      expect(_shownLook(tester).border.color, isNot(_brandBorder()));

      await tester.enterText(find.byType(TextField), typed);
      await tester.pumpAndSettle();

      expect(changes.last, typed);
      expect(_shownLook(tester).border.color, _brandBorder());
    }
  });

  testWidgets('DesignTextField property borders hover and invalid input', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final validity in FieldValidity.values) {
      await tester.pumpWidget(
        _sized(
          DesignTextField(
            key: UniqueKey(),
            controller: TextEditingController(),
            validity: validity,
          ),
        ),
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);

      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(DesignTextField)));
      await tester.pumpAndSettle();

      expect(
        _shownLook(tester).border.color,
        validity == FieldValidity.invalid ? colors.danger : colors.lineHover,
      );

      await mouse.removePointer();
    }
  });

  testWidgets('DesignTextField property hides an obscured value', (
    tester,
  ) async {
    for (final visibility in TextVisibility.values) {
      await tester.pumpWidget(
        _sized(
          DesignTextField(
            key: UniqueKey(),
            controller: TextEditingController(text: 'sk-secret'),
            visibility: visibility,
          ),
        ),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));

      expect(editable.obscureText, visibility == TextVisibility.obscured);
    }
  });

  testWidgets('DesignTextField property edits only an editable value', (
    tester,
  ) async {
    for (final (editability, shown, typed) in examplesOf(
      (random) => (
        oneOf(random, TextEditability.values),
        wordOf(random),
        wordOf(random),
      ),
      runs: 6,
    )) {
      await tester.pumpWidget(
        _sized(
          DesignTextField(
            key: UniqueKey(),
            controller: TextEditingController(text: shown),
            editability: editability,
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      final isReadOnly = editability == TextEditability.readOnly;

      expect(editable.readOnly, isReadOnly);
      expect(tester.testTextInput.hasAnyClients, !isReadOnly);
      expect(editable.controller.text, shown);

      if (!isReadOnly) {
        tester.testTextInput.enterText(typed);
        expect(editable.controller.text, typed);
      }
    }
  });

  testWidgets('DesignTextField property focuses itself when asked', (
    tester,
  ) async {
    for (final initialFocus in InitialFocus.values) {
      await tester.pumpWidget(
        _sized(
          DesignTextField(
            key: UniqueKey(),
            controller: TextEditingController(),
            initialFocus: initialFocus,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editable = tester.widget<EditableText>(find.byType(EditableText));

      expect(editable.focusNode.hasFocus, initialFocus == InitialFocus.focused);
    }
  });

  testWidgets('DesignTextArea property follows rows and its minimum height', (
    tester,
  ) async {
    for (final (rows, minimumHeight) in examplesOf(
      (random) =>
          (integerBetween(random, 1, 12), oneOf(random, [132.0, 200.0, 0.0])),
      runs: 8,
    )) {
      await tester.pumpWidget(
        _sized(
          DesignTextArea(
            key: UniqueKey(),
            controller: TextEditingController(),
            placeholder: 'notes',
            rows: rows,
            minimumHeight: minimumHeight,
          ),
        ),
      );

      final area = tester.getRect(find.byType(DesignTextArea));
      final hint = tester.getRect(find.text('notes'));
      final rowsHeight = rows * 16 * 1.55 + 24 + 2;

      expect(area.height, closeTo(max(minimumHeight, rowsHeight), 1e-6));
      expect(hint.left - area.left, 13);
      expect(hint.top - area.top, closeTo(13, 0.5));
    }
  });
}

Color _brandBorder() => DesignColors.forBrightness(Brightness.light).brand;
