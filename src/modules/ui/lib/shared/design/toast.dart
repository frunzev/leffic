import 'package:flutter/material.dart';

import 'bare_icon_button.dart';
import 'card_look.dart';
import 'design_colors.dart';
import 'design_metrics.dart';
import 'design_shadows.dart';
import 'design_typography.dart';
import 'icons/design_icon.dart';
import 'icons/design_icons.dart';
import 'surface_box.dart';

const double _stripeWidth = 4;
const double _dismissSide = 28;
const double _entranceDrop = 8;
const double _titleLineHeight = 1.4;
const double _detailLineHeight = 1.5;
const double _gradientSpan = 5.2;
const double _gradientTravel = 3.2;
const Duration _stripeSweep = Duration(milliseconds: 1800);
const Cubic _stripeCurve = Cubic(0.4, 0, 0.6, 1);
const String _dismissLabel = 'Dismiss';

enum ToastTone {
  progress(DesignIcons.start),
  success(DesignIcons.success),
  failure(DesignIcons.failure);

  const ToastTone(this.icon);

  final DesignIcons icon;

  Color colorIn(DesignColors colors) {
    return switch (this) {
      ToastTone.progress => colors.brand,
      ToastTone.success => colors.success,
      ToastTone.failure => colors.danger,
    };
  }
}

@immutable
class ToastMessage {
  const ToastMessage({required this.tone, required this.title, this.detail});

  final ToastTone tone;
  final String title;
  final String? detail;
}

class ToastStripe extends StatefulWidget {
  const ToastStripe({required this.tone, super.key});

  final ToastTone tone;

  @override
  State<ToastStripe> createState() => _ToastStripeState();
}

class _ToastStripeState extends State<ToastStripe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: _stripeSweep,
  )..repeat(reverse: true);
  late final Animation<double> _position = CurvedAnimation(
    parent: _sweep,
    curve: _stripeCurve,
  );

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  Widget _buildSweep(BuildContext context, Widget? child) {
    final colors = DesignColors.of(context);
    final top = -1 - _gradientTravel * _position.value;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0, top),
          end: Alignment(0, top + _gradientSpan),
          colors: [
            colors.brandSurfaceStrong,
            colors.brand,
            colors.brand,
            colors.brandSurfaceStrong,
          ],
          stops: const [0, 0.45, 0.55, 1],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);
    final isSweeping =
        widget.tone == ToastTone.progress &&
        !MediaQuery.disableAnimationsOf(context);

    if (!isSweeping) {
      return DecoratedBox(
        decoration: BoxDecoration(color: widget.tone.colorIn(colors)),
      );
    }

    return AnimatedBuilder(animation: _position, builder: _buildSweep);
  }
}

class ToastDismissButton extends StatelessWidget {
  const ToastDismissButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return BareIconButton(
      icon: DesignIcons.closePlain,
      semanticLabel: _dismissLabel,
      side: _dismissSide,
      hoverFill: colors.hover,
      hoverInk: colors.ink,
      onPressed: onPressed,
    );
  }
}

class Toast extends StatelessWidget {
  const Toast({required this.message, required this.onDismiss, super.key});

  final ToastMessage message;
  final VoidCallback onDismiss;

  Widget _buildEntrance(BuildContext context, double progress, Widget? child) {
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, _entranceDrop * (1 - progress)),
        child: child,
      ),
    );
  }

  Widget _buildText(DesignColors colors) {
    final detail = message.detail;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.step1,
      children: [
        Text(
          message.title,
          style: textStyleForSize(TextSizes.small)
              .copyWith(fontWeight: FontWeight.w600, height: _titleLineHeight),
        ),
        if (detail != null)
          Text(
            detail,
            style: textStyleForSize(
              TextSizes.small,
            ).copyWith(color: colors.inkSecondary, height: _detailLineHeight),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);
    final isStill = MediaQuery.disableAnimationsOf(context);
    final look = cardLookOf(colors: colors, shadows: DesignShadows.of(context));

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: isStill ? 1 : 0, end: 1),
      duration: Motion.duration,
      curve: Motion.curve,
      builder: _buildEntrance,
      child: SurfaceBox(
        look: look,
        borderRadius: Radii.medium,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.medium - 1),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.step4,
                  Spacing.step3,
                  Spacing.step3,
                  Spacing.step3,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Spacing.step3,
                  children: [
                    DesignIcon(
                      message.tone.icon,
                      color: message.tone.colorIn(colors),
                    ),
                    Expanded(child: _buildText(colors)),
                    ToastDismissButton(onPressed: onDismiss),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _stripeWidth,
                child: ToastStripe(tone: message.tone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
