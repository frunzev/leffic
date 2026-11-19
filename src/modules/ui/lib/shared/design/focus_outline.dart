import 'package:flutter/material.dart';

import 'design_colors.dart';
import 'pressable.dart';

const double focusOutlineWidth = 2;
const double _focusOutlineOffset = 2;
const double _strokeCentre = _focusOutlineOffset + focusOutlineWidth / 2;
const Color _hiddenOutline = Color(0x00000000);

RRect focusOutlineShape(Size size, double borderRadius) {
  final outlineBox = (Offset.zero & size).inflate(_strokeCentre);

  return RRect.fromRectAndRadius(
    outlineBox,
    Radius.circular(borderRadius + _strokeCentre),
  );
}

class FocusOutlinePainter extends CustomPainter {
  const FocusOutlinePainter({required this.color, required this.borderRadius});

  final Color color;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = focusOutlineWidth;

    canvas.drawRRect(focusOutlineShape(size, borderRadius), stroke);
  }

  @override
  bool shouldRepaint(FocusOutlinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius;
  }
}

class FocusOutline extends StatelessWidget {
  const FocusOutline({
    required this.state,
    required this.borderRadius,
    required this.child,
    super.key,
  });

  final InteractionState state;
  final double borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brand = DesignColors.of(context).brand;

    return CustomPaint(
      foregroundPainter: FocusOutlinePainter(
        color: state.isFocused ? brand : _hiddenOutline,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}
