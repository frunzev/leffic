import 'package:flutter/material.dart';

import 'design_colors.dart';
import 'design_metrics.dart';
import 'design_shadows.dart';
import 'focus_outline.dart';
import 'icons/design_icon.dart';
import 'icons/svg_path_parser.dart';
import 'pressable.dart';
import 'surface_box.dart';

const double _markSide = 18;
const double _checkMarkSide = 14;
const double _radioDotSide = 7;
const double _checkMarkStroke = 2.2;
const String _checkMarkPath = 'M3.5 8.5l3 3 6-6';
const Rect _checkMarkViewBox = Rect.fromLTWH(0, 0, 16, 16);
const Color _transparent = Color(0x00000000);

SurfaceLook choiceMarkLookOf({
  required InteractionState state,
  required bool isChecked,
  required DesignColors colors,
  required DesignShadows shadows,
}) {
  final Color borderColor;

  if (isChecked) {
    borderColor = _transparent;
  } else if (state.isHovered) {
    borderColor = colors.brand;
  } else {
    borderColor = colors.lineHover;
  }

  return SurfaceLook(
    fill: isChecked ? colors.brand : colors.surface,
    border: BorderSide(color: borderColor),
    shadows: shadows.raised,
    edgeHighlight: shadows.edgeHighlight,
  );
}

class _CheckMarkPainter extends CustomPainter {
  const _CheckMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final transform = viewBoxTransform(_checkMarkViewBox, size);
    final scale = size.width / _checkMarkViewBox.width;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _checkMarkStroke * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final mark = buildSvgPath(
      parseSvgPathData(_checkMarkPath),
      PathFillType.nonZero,
    );

    canvas.drawPath(mark.transform(transform.storage), stroke);
  }

  @override
  bool shouldRepaint(_CheckMarkPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class CheckMark extends StatelessWidget {
  const CheckMark({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _checkMarkSide,
      child: CustomPaint(
        painter: _CheckMarkPainter(DesignColors.of(context).brandMark),
      ),
    );
  }
}

class RadioDot extends StatelessWidget {
  const RadioDot({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _radioDotSide,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DesignColors.of(context).brandMark,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ChoiceMarkFace extends StatelessWidget {
  const _ChoiceMarkFace({
    required this.state,
    required this.isChecked,
    required this.borderRadius,
    required this.mark,
  });

  final InteractionState state;
  final bool isChecked;
  final double borderRadius;
  final Widget mark;

  @override
  Widget build(BuildContext context) {
    final look = choiceMarkLookOf(
      state: state,
      isChecked: isChecked,
      colors: DesignColors.of(context),
      shadows: DesignShadows.of(context),
    );

    return FocusOutline(
      state: state,
      borderRadius: borderRadius,
      child: SizedBox.square(
        dimension: _markSide,
        child: SurfaceBox(
          look: look,
          borderRadius: borderRadius,
          child: Center(child: isChecked ? mark : null),
        ),
      ),
    );
  }
}

class DesignCheckbox extends StatelessWidget {
  const DesignCheckbox({
    required this.isChecked,
    required this.onChanged,
    super.key,
  });

  final bool isChecked;
  final ValueChanged<bool>? onChanged;

  void _toggle() {
    onChanged?.call(!isChecked);
  }

  Widget _buildFace(BuildContext context, InteractionState state) {
    return _ChoiceMarkFace(
      state: state,
      isChecked: isChecked,
      borderRadius: Radii.extraSmall,
      mark: const CheckMark(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: isChecked,
      child: Pressable(
        onPressed: onChanged == null ? null : _toggle,
        builder: _buildFace,
      ),
    );
  }
}

class DesignRadio<T> extends StatelessWidget {
  const DesignRadio({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    super.key,
  });

  final T value;
  final T groupValue;
  final ValueChanged<T>? onChanged;

  bool get _isSelected => value == groupValue;

  void _select() {
    if (!_isSelected) {
      onChanged?.call(value);
    }
  }

  Widget _buildFace(BuildContext context, InteractionState state) {
    return _ChoiceMarkFace(
      state: state,
      isChecked: _isSelected,
      borderRadius: Radii.pill,
      mark: const RadioDot(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: _isSelected,
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        onPressed: onChanged == null ? null : _select,
        builder: _buildFace,
      ),
    );
  }
}
