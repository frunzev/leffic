import 'package:flutter/material.dart';

import 'button_look.dart';
import 'design_colors.dart';
import 'design_metrics.dart';
import 'design_shadows.dart';
import 'design_typography.dart';
import 'focus_outline.dart';
import 'icons/design_icon.dart';
import 'icons/design_icons.dart';
import 'pressable.dart';
import 'surface_box.dart';

enum ButtonSize {
  small(
    height: ControlHeights.small,
    padding: Spacing.step3,
    textSize: TextSizes.small,
  ),
  regular(
    height: ControlHeights.regular,
    padding: Spacing.step4,
    textSize: TextSizes.small,
  ),
  large(
    height: ControlHeights.large,
    padding: Spacing.step5,
    textSize: TextSizes.medium,
  );

  const ButtonSize({
    required this.height,
    required this.padding,
    required this.textSize,
  });

  final double height;
  final double padding;
  final double textSize;
}

typedef ButtonContentBuilder = Widget Function(Color iconColor);

List<double> _brightnessMatrix(double brightness) {
  return [
    ...[brightness, 0, 0, 0, 0],
    ...[0, brightness, 0, 0, 0],
    ...[0, 0, brightness, 0, 0],
    ...[0, 0, 0, 1, 0],
  ];
}

class _ButtonFace extends StatelessWidget {
  const _ButtonFace({
    required this.variant,
    required this.state,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.padding,
    required this.textSize,
    required this.contentBuilder,
  });

  final ButtonVariant variant;
  final InteractionState state;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsets padding;
  final double textSize;
  final ButtonContentBuilder contentBuilder;

  @override
  Widget build(BuildContext context) {
    final look = buttonLookOf(
      variant: variant,
      state: state,
      colors: DesignColors.of(context),
      shadows: DesignShadows.of(context),
    );
    final textStyle = DefaultTextStyle.of(context).style.merge(
      textStyleForSize(textSize)
          .copyWith(color: look.foreground, fontWeight: FontWeight.w500),
    );

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(_brightnessMatrix(look.brightness)),
      child: FocusOutline(
        state: state,
        borderRadius: borderRadius,
        child: SizedBox(
          width: width,
          height: height,
          child: SurfaceBox(
            look: look.surface,
            borderRadius: borderRadius,
            padding: padding,
            child: AnimatedDefaultTextStyle(
              style: textStyle,
              duration: Motion.duration,
              curve: Motion.curve,
              child: contentBuilder(look.iconColor),
            ),
          ),
        ),
      ),
    );
  }
}

class DesignButton extends StatelessWidget {
  const DesignButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailing,
    this.variant = ButtonVariant.standard,
    this.size = ButtonSize.regular,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final DesignIcons? icon;
  final Widget? trailing;
  final ButtonVariant variant;
  final ButtonSize size;

  Widget _buildContent(Color iconColor) {
    final leadingIcon = icon;
    final trailingWidget = trailing;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: Spacing.step2,
      children: [
        if (leadingIcon != null)
          DesignIcon(leadingIcon, size: IconSizes.small, color: iconColor),
        Text(label, maxLines: 1, softWrap: false),
        ?trailingWidget,
      ],
    );
  }

  Widget _buildFace(BuildContext context, InteractionState state) {
    return _ButtonFace(
      variant: variant,
      state: state,
      width: null,
      height: size.height,
      borderRadius: Radii.medium,
      padding: EdgeInsets.symmetric(horizontal: size.padding),
      textSize: size.textSize,
      contentBuilder: _buildContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(onPressed: onPressed, builder: _buildFace);
  }
}

class DesignIconButton extends StatelessWidget {
  const DesignIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.variant = ButtonVariant.standard,
    this.dimension = ControlHeights.regular,
    this.borderRadius = Radii.medium,
    this.iconColor,
    super.key,
  });

  final DesignIcons icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final double dimension;
  final double borderRadius;
  final Color? iconColor;

  Widget _buildIcon(Color lookIconColor) {
    return Center(
      child: DesignIcon(
        icon,
        size: IconSizes.small,
        color: iconColor ?? lookIconColor,
      ),
    );
  }

  Widget _buildFace(BuildContext context, InteractionState state) {
    return _ButtonFace(
      variant: variant,
      state: state,
      width: dimension,
      height: dimension,
      borderRadius: borderRadius,
      padding: EdgeInsets.zero,
      textSize: TextSizes.small,
      contentBuilder: _buildIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      builder: _buildFace,
    );
  }
}
