import 'package:flutter/widgets.dart';

import '../design_colors.dart';
import '../design_metrics.dart';
import 'design_icons.dart';
import 'icon_shape.dart';

Matrix4 viewBoxTransform(Rect viewBox, Size size) {
  final fitted = applyBoxFit(BoxFit.contain, viewBox.size, size);
  final destination = Alignment.center.inscribe(
    fitted.destination,
    Offset.zero & size,
  );
  final scale = destination.width / viewBox.width;

  return Matrix4.identity()
    ..translateByDouble(destination.left, destination.top, 0, 1)
    ..scaleByDouble(scale, scale, 1, 1)
    ..translateByDouble(-viewBox.left, -viewBox.top, 0, 1);
}

class ShapePainter extends CustomPainter {
  const ShapePainter({required this.shape, required this.color});

  final IconShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;
    final transform = viewBoxTransform(shape.viewBox, size).storage;

    for (final iconPath in shape.paths) {
      canvas.drawPath(iconPath.toPath().transform(transform), fill);
    }
  }

  @override
  bool shouldRepaint(ShapePainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.color != color;
  }
}

class ShapeView extends StatelessWidget {
  const ShapeView({
    required this.shape,
    required this.size,
    required this.color,
    super.key,
  });

  final IconShape shape;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: ShapePainter(shape: shape, color: color),
      ),
    );
  }
}

class DesignIcon extends StatelessWidget {
  const DesignIcon(
    this.icon, {
    this.size = IconSizes.regular,
    this.color,
    super.key,
  });

  final DesignIcons icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textColor = DefaultTextStyle.of(context).style.color;
    final inkColor = DesignColors.of(context).ink;

    return ShapeView(
      shape: icon.shape,
      size: size,
      color: color ?? textColor ?? inkColor,
    );
  }
}
