import 'dart:math';

import 'package:flutter/material.dart';

import '../design/design_button.dart';
import '../design/design_colors.dart';
import '../design/design_metrics.dart';
import '../design/design_typography.dart';
import '../design/icons/design_icon.dart';
import '../design/icons/design_icons.dart';

const double dashLength = 3;
const double _preferredDashGap = 2;
const double _borderWidth = 1;
const String _dropText = 'Drop a file here';
const String _browseLabel = 'Browse files';
const String _acceptedFilesHint = 'PDF, DOCX, PPTX or TXT · up to 20 MB';

int evenDashCount(double pathLength) {
  final preferredPeriod = dashLength + _preferredDashGap;
  final fittingCount = (pathLength / preferredPeriod).round();

  return max(1, fittingCount);
}

class _DashedOutlinePainter extends CustomPainter {
  const _DashedOutlinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = _borderWidth / 2;
    final outline = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - _borderWidth,
        size.height - _borderWidth,
      ),
      const Radius.circular(Radii.large - inset),
    );
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _borderWidth;
    final outlinePath = Path()..addRRect(outline);

    for (final metric in outlinePath.computeMetrics()) {
      final dashCount = evenDashCount(metric.length);
      final period = metric.length / dashCount;

      for (var index = 0; index < dashCount; index++) {
        final start = index * period;
        final dash = metric.extractPath(start, start + dashLength);

        canvas.drawPath(dash, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutlinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class Dropzone extends StatelessWidget {
  const Dropzone({required this.onBrowse, super.key});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return CustomPaint(
      foregroundPainter: _DashedOutlinePainter(color: colors.lineHover),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceSecondary,
          borderRadius: BorderRadius.circular(Radii.large),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: Spacing.step6 + _borderWidth,
            horizontal: Spacing.step4 + _borderWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: Spacing.step2,
            children: [
              DesignIcon(
                DesignIcons.fileSmall,
                size: IconSizes.regular,
                color: colors.inkTertiary,
              ),
              Text(
                _dropText,
                textAlign: TextAlign.center,
                style: textStyleForSize(TextSizes.small)
                    .copyWith(color: colors.ink),
              ),
              DesignButton(label: _browseLabel, onPressed: onBrowse),
              Text(
                _acceptedFilesHint,
                textAlign: TextAlign.center,
                style: textStyleForSize(TextSizes.extraSmall)
                    .copyWith(color: colors.inkTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
