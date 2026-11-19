import 'package:flutter/material.dart';

import 'design_colors.dart';
import 'design_shadows.dart';
import 'pressable.dart';
import 'surface_box.dart';

const Color _transparent = Color(0x00000000);
const double _plainBrightness = 1;
const double _dangerHoverBrightness = 0.92;

enum ButtonVariant { standard, primary, quiet, danger, dangerOutline, done }

@immutable
class ButtonLook {
  const ButtonLook({
    required this.surface,
    required this.foreground,
    required this.iconColor,
    required this.brightness,
  });

  final SurfaceLook surface;
  final Color foreground;
  final Color iconColor;
  final double brightness;
}

ButtonLook buttonLookOf({
  required ButtonVariant variant,
  required InteractionState state,
  required DesignColors colors,
  required DesignShadows shadows,
}) {
  final looks = _ButtonLooks(colors, shadows);

  if (!state.isEnabled) {
    return looks.disabled(variant);
  }

  return switch (variant) {
    ButtonVariant.standard => looks.standard(state),
    ButtonVariant.primary => looks.primary(state),
    ButtonVariant.quiet => looks.quiet(state),
    ButtonVariant.danger => looks.danger(state),
    ButtonVariant.dangerOutline => looks.dangerOutline(state),
    ButtonVariant.done => looks.done(state),
  };
}

class _ButtonLooks {
  const _ButtonLooks(this._colors, this._shadows);

  final DesignColors _colors;
  final DesignShadows _shadows;

  ButtonLook disabled(ButtonVariant variant) {
    if (variant == ButtonVariant.done) {
      return _withSuccessIcon(
        _flat(_colors.surface, _colors.success, _colors.inkSecondary),
      );
    }

    final isOutlinedDanger = variant == ButtonVariant.dangerOutline;
    final edgeColor = isOutlinedDanger ? _colors.danger : _colors.line;
    final foreground = isOutlinedDanger ? _colors.danger : _colors.inkTertiary;

    return _flat(_colors.surfaceSecondary, edgeColor, foreground);
  }

  ButtonLook standard(InteractionState state) {
    if (state.isPressed) {
      return _flat(_colors.surfaceTertiary, _colors.lineHover, _colors.ink);
    }

    if (state.isHovered) {
      return _raised(_colors.surfaceSecondary, _colors.lineHover, _colors.ink);
    }

    return _raised(_colors.surface, _colors.lineStrong, _colors.ink);
  }

  ButtonLook primary(InteractionState state) {
    if (state.isPressed) {
      return _flat(_colors.brandStrong, _transparent, _colors.onBrand);
    }

    final fill = state.isHovered ? _colors.brandStrong : _colors.brand;

    return _look(
      SurfaceLook(
        fill: fill,
        border: const BorderSide(color: _transparent),
        shadows: _shadows.brand,
        edgeHighlight: _transparent,
      ),
      _colors.onBrand,
    );
  }

  ButtonLook quiet(InteractionState state) {
    if (state.isPressed || state.isHovered) {
      return _flat(_colors.hover, _transparent, _colors.ink);
    }

    return _flat(_transparent, _transparent, _colors.inkSecondary);
  }

  ButtonLook danger(InteractionState state) {
    final isActive = state.isPressed || state.isHovered;
    final brightness = isActive ? _dangerHoverBrightness : _plainBrightness;
    final base = state.isPressed
        ? _flat(_colors.danger, _transparent, _colors.onBrand)
        : _raised(_colors.danger, _transparent, _colors.onBrand);

    return ButtonLook(
      surface: base.surface,
      foreground: base.foreground,
      iconColor: base.iconColor,
      brightness: brightness,
    );
  }

  ButtonLook dangerOutline(InteractionState state) {
    if (state.isPressed) {
      return _flat(_colors.dangerSurface, _colors.danger, _colors.danger);
    }

    final fill = state.isHovered ? _colors.dangerSurface : _colors.surface;

    return _raised(fill, _colors.danger, _colors.danger);
  }

  ButtonLook done(InteractionState state) {
    final base = state.isPressed
        ? _flat(_colors.surface, _colors.success, _colors.inkSecondary)
        : _raised(_colors.surface, _colors.success, _colors.inkSecondary);

    return _withSuccessIcon(base);
  }

  ButtonLook _withSuccessIcon(ButtonLook base) {
    return ButtonLook(
      surface: base.surface,
      foreground: base.foreground,
      iconColor: _colors.success,
      brightness: base.brightness,
    );
  }

  ButtonLook _raised(Color fill, Color edgeColor, Color foreground) {
    return _look(
      SurfaceLook(
        fill: fill,
        border: BorderSide(color: edgeColor),
        shadows: _shadows.raised,
        edgeHighlight: _shadows.edgeHighlight,
      ),
      foreground,
    );
  }

  ButtonLook _flat(Color fill, Color edgeColor, Color foreground) {
    return _look(
      SurfaceLook(
        fill: fill,
        border: BorderSide(color: edgeColor),
        shadows: const [],
        edgeHighlight: _transparent,
      ),
      foreground,
    );
  }

  ButtonLook _look(SurfaceLook surface, Color foreground) {
    return ButtonLook(
      surface: surface,
      foreground: foreground,
      iconColor: foreground,
      brightness: _plainBrightness,
    );
  }
}
