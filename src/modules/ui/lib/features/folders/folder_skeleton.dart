import 'package:flutter/widgets.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/meter.dart';
import '../../shared/design/surface_box.dart';
import 'folder_panel.dart';
import 'shimmer_bar.dart';
import 'unit_link.dart';

const String _loadingLabel = 'Loading folder contents';
const Color _transparent = Color(0x00000000);
const double _fillWidth = double.infinity;
const Size _dotSize = Size.square(IconSizes.regular);
const Size _badgeSize = Size(56, 20);
const double _skeletonButtonWidth = 148;
const double _dueHeadingBarWidth = 88;
const double _dueProgressBarWidth = 104;
const double _dueBreakdownBarWidth = 260;
const double _unitsCountBarWidth = 64;
const double _unitsNoteBarWidth = 80;
const Widget _badge = SkeletonBlock(size: _badgeSize, borderRadius: Radii.pill);
const List<SkeletonRow> _rows = [
  SkeletonRow(nameWidthFactor: 0.46, metaWidthFactor: 0.24),
  SkeletonRow(nameWidthFactor: 0.62, metaWidthFactor: 0.18, trailing: _badge),
  SkeletonRow(nameWidthFactor: 0.38, metaWidthFactor: 0.22, trailing: _badge),
  SkeletonRow(nameWidthFactor: 0.54, metaWidthFactor: 0.16),
];

class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    required this.size,
    required this.borderRadius,
    super.key,
  });

  final Size size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DesignColors.of(context).surfaceTertiary,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class SkeletonRow extends StatelessWidget {
  const SkeletonRow({
    required this.nameWidthFactor,
    required this.metaWidthFactor,
    this.trailing,
    super.key,
  });

  final double nameWidthFactor;
  final double metaWidthFactor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final rowEnd = trailing;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.step4),
      child: Row(
        spacing: Spacing.step3,
        children: [
          const SkeletonBlock(size: _dotSize, borderRadius: Radii.small),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Spacing.step1,
              children: [
                FractionallySizedBox(
                  widthFactor: nameWidthFactor,
                  child: const ShimmerBar(width: _fillWidth),
                ),
                FractionallySizedBox(
                  widthFactor: metaWidthFactor,
                  child: const ShimmerBar(width: _fillWidth),
                ),
              ],
            ),
          ),
          ?rowEnd,
        ],
      ),
    );
  }
}

Widget _edgedRow(SkeletonRow row, BorderSide bottomEdge) {
  return Container(
    constraints: const BoxConstraints(minHeight: unitRowMinimumHeight),
    decoration: BoxDecoration(border: Border(bottom: bottomEdge)),
    child: row,
  );
}

class DueSkeleton extends StatelessWidget {
  const DueSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const FolderPanel(
      padding: EdgeInsets.all(Spacing.step5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBar(width: _dueHeadingBarWidth),
              ShimmerBar(width: _dueProgressBarWidth),
            ],
          ),
          SizedBox(height: Spacing.step2),
          Meter(fraction: 0),
          SizedBox(height: Spacing.step4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBar(width: _dueBreakdownBarWidth),
              ShimmerBar(
                width: _skeletonButtonWidth,
                height: ControlHeights.large,
                borderRadius: Radii.medium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UnitsSkeleton extends StatelessWidget {
  const UnitsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final line = BorderSide(color: DesignColors.of(context).line);
    final lastIndex = _rows.length - 1;
    final look = SurfaceLook(
      fill: _transparent,
      border: line,
      shadows: const [],
      edgeHighlight: _transparent,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShimmerBar(width: _unitsCountBarWidth),
            ShimmerBar(width: _unitsNoteBarWidth),
          ],
        ),
        const SizedBox(height: Spacing.step3),
        Semantics(
          label: _loadingLabel,
          liveRegion: true,
          child: SurfaceBox(
            look: look,
            borderRadius: Radii.large,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < lastIndex; index++)
                  _edgedRow(_rows[index], line),
                _edgedRow(_rows[lastIndex], BorderSide.none),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
