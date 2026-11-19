import 'package:flutter/widgets.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';

const Duration _sweepDuration = Duration(milliseconds: 1400);
const double _imageWidthInBars = 4;
const List<double> _gradientStops = [0.25, 0.37, 0.63];
const double _barHeight = 12;
const double _stillSweep = 1;

LinearGradient shimmerGradient({
  required double position,
  required Color base,
  required Color highlight,
}) {
  final imageStart = (1 - _imageWidthInBars) * position;
  final imageEnd = imageStart + _imageWidthInBars;

  return LinearGradient(
    begin: Alignment(2 * imageStart - 1, 0),
    end: Alignment(2 * imageEnd - 1, 0),
    colors: [base, highlight, base],
    stops: _gradientStops,
  );
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({
    required this.sweep,
    required this.base,
    required this.highlight,
    required this.borderRadius,
  }) : super(repaint: sweep);

  final Animation<double> sweep;
  final Color base;
  final Color highlight;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final position = 1 - Curves.ease.transform(sweep.value);
    final bar = Offset.zero & size;
    final gradient = shimmerGradient(
      position: position,
      base: base,
      highlight: highlight,
    );
    final fill = Paint()..shader = gradient.createShader(bar);

    canvas.drawRRect(
      RRect.fromRectAndRadius(bar, Radius.circular(borderRadius)),
      fill,
    );
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) {
    return oldDelegate.sweep != sweep ||
        oldDelegate.base != base ||
        oldDelegate.highlight != highlight ||
        oldDelegate.borderRadius != borderRadius;
  }
}

class ShimmerBar extends StatefulWidget {
  const ShimmerBar({
    required this.width,
    this.height = _barHeight,
    this.borderRadius = Radii.pill,
    super.key,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerBar> createState() => _ShimmerBarState();
}

class _ShimmerBarState extends State<ShimmerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: _sweepDuration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (MediaQuery.disableAnimationsOf(context)) {
      _sweep.value = _stillSweep;
      return;
    }

    if (!_sweep.isAnimating) {
      _sweep.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: CustomPaint(
        painter: _ShimmerPainter(
          sweep: _sweep,
          base: colors.surfaceTertiary,
          highlight: colors.hover,
          borderRadius: widget.borderRadius,
        ),
      ),
    );
  }
}
