import 'package:flutter/material.dart';

import 'design_colors.dart';
import 'design_metrics.dart';
import 'design_shadows.dart';
import 'design_typography.dart';
import 'focus_outline.dart';
import 'pressable.dart';
import 'surface_box.dart';

const double _trackPadding = 3;
const double _segmentGap = 2;
const Color _transparent = Color(0x00000000);

enum SegmentedSize {
  regular(
    minimumWidth: 44,
    minimumHeight: 32,
    horizontalPadding: Spacing.step2,
    textSize: TextSizes.small,
  ),
  large(
    minimumWidth: 0,
    minimumHeight: 36,
    horizontalPadding: Spacing.step3,
    textSize: TextSizes.medium,
  );

  const SegmentedSize({
    required this.minimumWidth,
    required this.minimumHeight,
    required this.horizontalPadding,
    required this.textSize,
  });

  final double minimumWidth;
  final double minimumHeight;
  final double horizontalPadding;
  final double textSize;
}

class SegmentFace extends StatelessWidget {
  const SegmentFace({
    required this.label,
    required this.isSelected,
    required this.size,
    required this.state,
    super.key,
  });

  final String label;
  final bool isSelected;
  final SegmentedSize size;
  final InteractionState state;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);
    final shadows = DesignShadows.of(context);
    final isInked = isSelected || state.isHovered;
    final look = SurfaceLook(
      fill: isSelected ? colors.surface : _transparent,
      border: BorderSide.none,
      shadows: isSelected ? shadows.raised : const [],
      edgeHighlight: isSelected ? shadows.edgeHighlight : _transparent,
    );
    final textStyle = DefaultTextStyle.of(context).style.merge(
      textStyleForSize(size.textSize).copyWith(
        color: isInked ? colors.ink : colors.inkSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
    );

    return FocusOutline(
      state: state,
      borderRadius: Radii.small,
      child: SurfaceBox(
        look: look,
        borderRadius: Radii.small,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: size.minimumWidth,
            minHeight: size.minimumHeight,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.horizontalPadding),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: AnimatedDefaultTextStyle(
                style: textStyle,
                duration: Motion.duration,
                curve: Motion.curve,
                child: Text(label, textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isSelected,
    required this.size,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final SegmentedSize size;
  final VoidCallback onPressed;

  Widget _buildFace(BuildContext context, InteractionState state) {
    return SegmentFace(
      label: label,
      isSelected: isSelected,
      size: size,
      state: state,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: Pressable(onPressed: onPressed, builder: _buildFace),
    );
  }
}

class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    required this.choices,
    required this.labelOf,
    required this.selected,
    required this.onSelected,
    this.size = SegmentedSize.regular,
    super.key,
  });

  final List<T> choices;
  final String Function(T choice) labelOf;
  final T selected;
  final ValueChanged<T> onSelected;
  final SegmentedSize size;

  void _choose(T choice) {
    if (choice != selected) {
      onSelected(choice);
    }
  }

  Widget _segmentFor(T choice) {
    return _Segment(
      label: labelOf(choice),
      isSelected: choice == selected,
      size: size,
      onPressed: () => _choose(choice),
    );
  }

  Widget _arrange(List<Widget> segments) {
    return switch (size) {
      SegmentedSize.regular => Wrap(
        spacing: _segmentGap,
        runSpacing: _segmentGap,
        children: segments,
      ),
      SegmentedSize.large => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: _segmentGap,
          children: [for (final segment in segments) Expanded(child: segment)],
        ),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final segments = [for (final choice in choices) _segmentFor(choice)];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignColors.of(context).surfaceTertiary,
        borderRadius: BorderRadius.circular(Radii.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_trackPadding),
        child: _arrange(segments),
      ),
    );
  }
}
