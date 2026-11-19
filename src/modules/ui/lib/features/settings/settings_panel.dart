import 'package:flutter/material.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_shadows.dart';
import '../../shared/design/design_typography.dart';
import '../../shared/design/panel_look.dart';
import '../../shared/design/surface_box.dart';
import 'settings_layout.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({
    required this.title,
    required this.text,
    required this.body,
    super.key,
  });

  final String title;
  final String text;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);
    final look = raisedPanelLookOf(
      colors: colors,
      shadows: DesignShadows.of(context),
    );

    return SurfaceBox(
      look: look,
      borderRadius: Radii.large,
      padding: const EdgeInsets.all(Spacing.step5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.step4,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Spacing.step1,
            children: [
              Text(
                title,
                style: textStyleForSize(
                  TextSizes.large,
                  addedLetterSpacingInEm: titleTracking,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                text,
                style: textStyleForSize(TextSizes.small)
                    .copyWith(color: colors.inkSecondary),
              ),
            ],
          ),
          body,
        ],
      ),
    );
  }
}
