import 'dart:math';

import 'package:flutter/material.dart';

import 'design_metrics.dart';

const Offset _edgeHighlightOffset = Offset(0, 1);

@immutable
class SurfaceLook {
  const SurfaceLook({
    required this.fill,
    required this.border,
    required this.shadows,
    required this.edgeHighlight,
  });

  final Color fill;
  final BorderSide border;
  final List<BoxShadow> shadows;
  final Color edgeHighlight;
}

Path edgeHighlightBand(Size size, double radius) {
  final paddingBox = RRect.fromRectAndRadius(
    Offset.zero & size,
    Radius.circular(radius),
  );
  final shiftedBox = paddingBox.shift(_edgeHighlightOffset);

  return Path.combine(
    PathOperation.difference,
    Path()..addRRect(paddingBox),
    Path()..addRRect(shiftedBox),
  );
}

class _EdgeHighlightPainter extends CustomPainter {
  const _EdgeHighlightPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(edgeHighlightBand(size, radius), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_EdgeHighlightPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class SurfaceBox extends StatelessWidget {
  const SurfaceBox({
    required this.look,
    required this.borderRadius,
    required this.child,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final SurfaceLook look;
  final double borderRadius;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final innerRadius = max(0.0, borderRadius - look.border.width);

    return AnimatedContainer(
      duration: Motion.duration,
      curve: Motion.curve,
      decoration: BoxDecoration(
        color: look.fill,
        border: Border.fromBorderSide(look.border),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: look.shadows,
      ),
      child: CustomPaint(
        painter: _EdgeHighlightPainter(
          color: look.edgeHighlight,
          radius: innerRadius,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
