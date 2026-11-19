import 'package:flutter/material.dart';

import 'design_colors.dart';

typedef PageForSettings = Widget Function(RouteSettings settings);

class OpaquePageRoute extends PageRoute<void> {
  OpaquePageRoute({required super.settings, required this.pageFor});

  final PageForSettings pageFor;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final colors = DesignColors.of(context);

    return ColoredBox(color: colors.surfaceSecondary, child: pageFor(settings));
  }
}
