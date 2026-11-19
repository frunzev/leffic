import 'package:flutter/material.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';

const String aiProviderKeysTitle = 'AI provider keys';
const double titleTracking = -0.01;
const double _settingsWidth = 880;
const double _sectionNavWidth = 208;
const double _sectionNavItemHeight = 40;
const EdgeInsets _settingsPadding = EdgeInsets.fromLTRB(
  Spacing.step6,
  Spacing.step7,
  Spacing.step6,
  Spacing.step8,
);

class SettingsLayout extends StatelessWidget {
  const SettingsLayout({required this.panel, super.key});

  final Widget panel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _settingsWidth),
          child: Padding(
            padding: _settingsPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Spacing.step5,
              children: [
                Text(
                  'Settings',
                  style: textStyleForSize(
                    TextSizes.extraLarge,
                    addedLetterSpacingInEm: titleTracking,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Spacing.step6,
                  children: [
                    const SizedBox(
                      width: _sectionNavWidth,
                      child: _CurrentSection(label: aiProviderKeysTitle),
                    ),
                    Expanded(child: panel),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentSection extends StatelessWidget {
  const _CurrentSection({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: _sectionNavItemHeight),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.step3),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: colors.brandSurfaceStrong,
        borderRadius: BorderRadius.circular(Radii.medium),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: textStyleForSize(TextSizes.small)
            .copyWith(color: colors.brandStrong, fontWeight: FontWeight.w600),
      ),
    );
  }
}
