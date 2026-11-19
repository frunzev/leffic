import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'design_colors.dart';
import 'design_metrics.dart';
import 'design_shadows.dart';
import 'pressable.dart';
import 'surface_box.dart';

const Color _transparent = Color(0x00000000);

enum FieldValidity { valid, invalid }

typedef FocusedFieldBuilder = Widget Function(
  BuildContext context,
  FocusNode focusNode,
);

SurfaceLook inputLookOf({
  required InteractionState state,
  required FieldValidity validity,
  required DesignColors colors,
  required DesignShadows shadows,
}) {
  final Color borderColor;

  if (validity == FieldValidity.invalid) {
    borderColor = colors.danger;
  } else if (state.isFocused) {
    borderColor = colors.brand;
  } else if (state.isHovered) {
    borderColor = colors.lineHover;
  } else {
    borderColor = colors.lineStrong;
  }

  return SurfaceLook(
    fill: colors.surface,
    border: BorderSide(color: borderColor),
    shadows: state.isFocused ? shadows.focusRing : shadows.raised,
    edgeHighlight: state.isFocused ? _transparent : shadows.edgeHighlight,
  );
}

class InputFrame extends StatefulWidget {
  const InputFrame({
    required this.validity,
    required this.height,
    required this.builder,
    super.key,
  });

  final FieldValidity validity;
  final double height;
  final FocusedFieldBuilder builder;

  @override
  State<InputFrame> createState() => _InputFrameState();
}

class _InputFrameState extends State<InputFrame> {
  final FocusNode _focusNode = FocusNode();
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_showFocus);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _showFocus() {
    setState(() {});
  }

  void _enter(PointerEnterEvent event) {
    setState(() {
      _isHovered = true;
    });
  }

  void _exit(PointerExitEvent event) {
    setState(() {
      _isHovered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = InteractionState(
      isEnabled: true,
      isHovered: _isHovered,
      isPressed: false,
      isFocused: _focusNode.hasFocus,
    );
    final look = inputLookOf(
      state: state,
      validity: widget.validity,
      colors: DesignColors.of(context),
      shadows: DesignShadows.of(context),
    );

    return MouseRegion(
      onEnter: _enter,
      onExit: _exit,
      child: SizedBox(
        height: widget.height,
        child: SurfaceBox(
          look: look,
          borderRadius: Radii.medium,
          child: widget.builder(context, _focusNode),
        ),
      ),
    );
  }
}
