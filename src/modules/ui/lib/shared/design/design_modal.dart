import 'dart:ui';

import 'package:flutter/material.dart';

import 'button_look.dart';
import 'design_button.dart';
import 'design_colors.dart';
import 'design_metrics.dart';
import 'design_shadows.dart';
import 'design_typography.dart';
import 'icons/design_icons.dart';
import 'panel_look.dart';
import 'surface_box.dart';

const double _scrimBlur = 3;
const double _titleLetterSpacingInEm = -0.01;
const double _headingGap = 2;
const String _closeLabel = 'Close dialog';

enum ModalWidth {
  regular(420),
  wide(600);

  const ModalWidth(this.maximum);

  final double maximum;
}

class DesignModal extends StatelessWidget {
  const DesignModal({
    required this.title,
    required this.body,
    required this.actions,
    this.description,
    this.width = ModalWidth.regular,
    super.key,
  });

  final String title;
  final String? description;
  final Widget body;
  final List<Widget> actions;
  final ModalWidth width;

  Widget _buildHeading(DesignColors colors) {
    final modalDescription = description;

    return Padding(
      padding: const EdgeInsets.only(top: Spacing.step1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: _headingGap,
        children: [
          Text(
            title,
            style: textStyleForSize(
              TextSizes.medium,
              addedLetterSpacingInEm: _titleLetterSpacingInEm,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          if (modalDescription != null)
            Text(
              modalDescription,
              style: textStyleForSize(TextSizes.small)
                  .copyWith(color: colors.inkSecondary),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);
    final shadows = DesignShadows.of(context);
    final look = floatingPanelLookOf(colors: colors, shadows: shadows);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width.maximum),
      child: SurfaceBox(
        look: look,
        borderRadius: Radii.large,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.large - 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.step5,
                  Spacing.step4,
                  Spacing.step4,
                  0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Spacing.step3,
                  children: [
                    Expanded(child: _buildHeading(colors)),
                    DesignIconButton(
                      icon: DesignIcons.closePlain,
                      semanticLabel: _closeLabel,
                      variant: ButtonVariant.quiet,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.step5,
                    Spacing.step4,
                    Spacing.step5,
                    Spacing.step2,
                  ),
                  child: body,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.step5,
                  Spacing.step3,
                  Spacing.step5,
                  Spacing.step5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: Spacing.step2,
                  children: actions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModalBackdrop extends StatelessWidget {
  const ModalBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: _scrimBlur, sigmaY: _scrimBlur),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.step4),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _ModalPage {
  const _ModalPage(this.builder);

  final WidgetBuilder builder;

  Widget build(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return ModalBackdrop(child: builder(context));
  }
}

Future<T?> showDesignModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: DesignColors.of(context).scrim,
    transitionDuration: Duration.zero,
    pageBuilder: _ModalPage(builder).build,
  );
}
