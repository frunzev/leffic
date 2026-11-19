import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/button_look.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_shadows.dart';
import 'package:leffic/shared/design/pressable.dart';

import '../../support/property.dart';

const Color _transparent = Color(0x00000000);

enum _StateKind { idle, hovered, pressed, disabled }

typedef _ExpectedLook = ({
  Color fill,
  Color border,
  List<BoxShadow> shadows,
  Color edge,
  Color foreground,
  double brightness,
});

InteractionState _stateOf(Random random) {
  return InteractionState(
    isEnabled: random.nextInt(4) > 0,
    isHovered: random.nextBool(),
    isPressed: random.nextBool(),
    isFocused: random.nextBool(),
  );
}

_StateKind _kindOf(InteractionState state) {
  if (!state.isEnabled) {
    return _StateKind.disabled;
  }

  if (state.isPressed) {
    return _StateKind.pressed;
  }

  return state.isHovered ? _StateKind.hovered : _StateKind.idle;
}

_ExpectedLook _cssLook(
  ButtonVariant variant,
  _StateKind kind,
  DesignColors colors,
  DesignShadows shadows,
) {
  final raised = (shadows: shadows.raised, edge: shadows.edgeHighlight);
  const flat = (shadows: <BoxShadow>[], edge: _transparent);
  final brand = (shadows: shadows.brand, edge: _transparent);

  final (fill, border, elevation, foreground, brightness) = switch ((
    variant,
    kind,
  )) {
    (ButtonVariant.done, _StateKind.pressed || _StateKind.disabled) => (
      colors.surface,
      colors.success,
      flat,
      colors.inkSecondary,
      1.0,
    ),
    (ButtonVariant.done, _) => (
      colors.surface,
      colors.success,
      raised,
      colors.inkSecondary,
      1.0,
    ),
    (ButtonVariant.dangerOutline, _StateKind.disabled) => (
      colors.surfaceSecondary,
      colors.danger,
      flat,
      colors.danger,
      1.0,
    ),
    (_, _StateKind.disabled) => (
      colors.surfaceSecondary,
      colors.line,
      flat,
      colors.inkTertiary,
      1.0,
    ),
    (ButtonVariant.standard, _StateKind.idle) => (
      colors.surface,
      colors.lineStrong,
      raised,
      colors.ink,
      1.0,
    ),
    (ButtonVariant.standard, _StateKind.hovered) => (
      colors.surfaceSecondary,
      colors.lineHover,
      raised,
      colors.ink,
      1.0,
    ),
    (ButtonVariant.standard, _) => (
      colors.surfaceTertiary,
      colors.lineHover,
      flat,
      colors.ink,
      1.0,
    ),
    (ButtonVariant.primary, _StateKind.idle) => (
      colors.brand,
      _transparent,
      brand,
      colors.onBrand,
      1.0,
    ),
    (ButtonVariant.primary, _StateKind.hovered) => (
      colors.brandStrong,
      _transparent,
      brand,
      colors.onBrand,
      1.0,
    ),
    (ButtonVariant.primary, _) => (
      colors.brandStrong,
      _transparent,
      flat,
      colors.onBrand,
      1.0,
    ),
    (ButtonVariant.quiet, _StateKind.idle) => (
      _transparent,
      _transparent,
      flat,
      colors.inkSecondary,
      1.0,
    ),
    (ButtonVariant.quiet, _) => (
      colors.hover,
      _transparent,
      flat,
      colors.ink,
      1.0,
    ),
    (ButtonVariant.danger, _StateKind.idle) => (
      colors.danger,
      _transparent,
      raised,
      colors.onBrand,
      1.0,
    ),
    (ButtonVariant.danger, _StateKind.hovered) => (
      colors.danger,
      _transparent,
      raised,
      colors.onBrand,
      0.92,
    ),
    (ButtonVariant.danger, _) => (
      colors.danger,
      _transparent,
      flat,
      colors.onBrand,
      0.92,
    ),
    (ButtonVariant.dangerOutline, _StateKind.idle) => (
      colors.surface,
      colors.danger,
      raised,
      colors.danger,
      1.0,
    ),
    (ButtonVariant.dangerOutline, _StateKind.hovered) => (
      colors.dangerSurface,
      colors.danger,
      raised,
      colors.danger,
      1.0,
    ),
    (ButtonVariant.dangerOutline, _) => (
      colors.dangerSurface,
      colors.danger,
      flat,
      colors.danger,
      1.0,
    ),
  };

  return (
    fill: fill,
    border: border,
    shadows: elevation.shadows,
    edge: elevation.edge,
    foreground: foreground,
    brightness: brightness,
  );
}

void main() {
  test('buttonLookOf property matches app-controls.css in every state', () {
    forAll(
      (random) => (
        oneOf(random, ButtonVariant.values),
        _stateOf(random),
        oneOf(random, Brightness.values),
      ),
      (example) {
        final (variant, state, brightness) = example;
        final colors = DesignColors.forBrightness(brightness);
        final shadows = DesignShadows.forBrightness(brightness);
        final look = buttonLookOf(
          variant: variant,
          state: state,
          colors: colors,
          shadows: shadows,
        );
        final expected = _cssLook(variant, _kindOf(state), colors, shadows);

        expect(look.surface.fill, expected.fill);
        expect(look.surface.border, BorderSide(color: expected.border));
        expect(look.surface.shadows, expected.shadows);
        expect(look.surface.edgeHighlight, expected.edge);
        expect(look.foreground, expected.foreground);
        expect(look.brightness, expected.brightness);
        expect(
          look.iconColor,
          variant == ButtonVariant.done ? colors.success : expected.foreground,
        );
      },
      runs: 400,
    );
  });

  test('buttonLookOf property ignores focus, which only adds the outline', () {
    forAll(
      (random) => (oneOf(random, ButtonVariant.values), _stateOf(random)),
      (example) {
        final (variant, state) = example;
        final colors = DesignColors.forBrightness(Brightness.light);
        final shadows = DesignShadows.forBrightness(Brightness.light);
        final unfocused = InteractionState(
          isEnabled: state.isEnabled,
          isHovered: state.isHovered,
          isPressed: state.isPressed,
          isFocused: false,
        );
        final focusedLook = buttonLookOf(
          variant: variant,
          state: state,
          colors: colors,
          shadows: shadows,
        );
        final unfocusedLook = buttonLookOf(
          variant: variant,
          state: unfocused,
          colors: colors,
          shadows: shadows,
        );

        expect(focusedLook.surface.fill, unfocusedLook.surface.fill);
        expect(focusedLook.foreground, unfocusedLook.foreground);
      },
    );
  });
}
