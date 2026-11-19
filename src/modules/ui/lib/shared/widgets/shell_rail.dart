import 'package:flutter/material.dart';

import '../design/design_colors.dart';
import '../design/design_dropdown.dart';
import '../design/design_metrics.dart';
import '../design/icons/design_icon.dart';
import '../design/icons/design_icons.dart';
import 'rail_item.dart';

const double _logoSize = 32;
const double _railBorderWidth = 1;

enum RailDestination { home, ask }

class ShellRail extends StatelessWidget {
  const ShellRail({
    required this.current,
    required this.onHome,
    required this.onAsk,
    required this.onSettings,
    super.key,
  });

  final RailDestination? current;
  final VoidCallback onHome;
  final VoidCallback onAsk;
  final VoidCallback onSettings;

  Widget _buildProfile(BuildContext context, OverlayPortalController menu) {
    return RailItem(
      icon: DesignIcons.profile,
      label: 'Profile',
      isCurrent: false,
      onPressed: menu.toggle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.step3,
        horizontal: Spacing.step2,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        border: Border(
          right: BorderSide(color: colors.line, width: _railBorderWidth),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.step4),
                child: Center(
                  child: DesignIcon(
                    DesignIcons.logo,
                    size: _logoSize,
                    color: colors.brand,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Spacing.step1,
                children: [
                  RailItem(
                    icon: DesignIcons.home,
                    label: 'Home',
                    isCurrent: current == RailDestination.home,
                    onPressed: onHome,
                  ),
                  RailItem(
                    icon: DesignIcons.ask,
                    label: 'Ask',
                    isCurrent: current == RailDestination.ask,
                    onPressed: onAsk,
                  ),
                ],
              ),
            ],
          ),
          DesignDropdown(
            placement: DropdownPlacement.besideEnd,
            entries: [
              DropdownAction(
                icon: DesignIcons.settings,
                label: 'Settings',
                onSelected: onSettings,
              ),
            ],
            anchorBuilder: _buildProfile,
          ),
        ],
      ),
    );
  }
}
