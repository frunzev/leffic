import 'package:flutter/material.dart';

import '../design/design_colors.dart';
import '../design/design_metrics.dart';
import '../navigation/home_navigation.dart';
import '../navigation/routes.dart';
import 'ask_panel_scope.dart';
import 'shell_rail.dart';

const double _askPanelWidth = 380;

class AppShell extends StatelessWidget {
  const AppShell({required this.selectedRoute, required this.body, super.key});

  final String selectedRoute;
  final Widget body;

  void _openSettings(BuildContext context) {
    Navigator.of(context)
        .pushNamedAndRemoveUntil(Routes.settings, (route) => route.isFirst);
  }

  RailDestination? _currentDestination(AskPanelController askPanel) {
    if (askPanel.isOpen) {
      return RailDestination.ask;
    }

    return selectedRoute == Routes.folder ? RailDestination.home : null;
  }

  @override
  Widget build(BuildContext context) {
    final askPanel = AskPanelScope.of(context);

    return Scaffold(
      backgroundColor: DesignColors.of(context).surfaceSecondary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: LayoutSizes.railWidth),
            child: body,
          ),
          if (askPanel.controller.isOpen)
            Positioned.fill(
              left: LayoutSizes.railWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  heightFactor: 1,
                  child: SizedBox(width: _askPanelWidth, child: askPanel.panel),
                ),
              ),
            ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: LayoutSizes.railWidth,
            child: ShellRail(
              current: _currentDestination(askPanel.controller),
              onHome: () => openHomeFolder(context),
              onAsk: askPanel.controller.toggle,
              onSettings: () => _openSettings(context),
            ),
          ),
        ],
      ),
    );
  }
}
