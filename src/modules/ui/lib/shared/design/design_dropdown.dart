import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design_divider.dart';
import 'dropdown_parts.dart';
import 'icons/design_icons.dart';

export 'dropdown_parts.dart' show DropdownItem, DropdownPanel, DropdownTone;

typedef DropdownAnchorBuilder = Widget Function(
  BuildContext context,
  OverlayPortalController menu,
);

@immutable
class DropdownPlacement {
  const DropdownPlacement({
    required this.targetAnchor,
    required this.followerAnchor,
    required this.offset,
  });

  static const DropdownPlacement belowStart = DropdownPlacement(
    targetAnchor: Alignment.bottomLeft,
    followerAnchor: Alignment.topLeft,
    offset: Offset(0, 8),
  );

  static const DropdownPlacement belowEnd = DropdownPlacement(
    targetAnchor: Alignment.bottomRight,
    followerAnchor: Alignment.topRight,
    offset: Offset(0, 8),
  );

  static const DropdownPlacement besideEnd = DropdownPlacement(
    targetAnchor: Alignment.bottomRight,
    followerAnchor: Alignment.bottomLeft,
    offset: Offset(8, 0),
  );

  final Alignment targetAnchor;
  final Alignment followerAnchor;
  final Offset offset;
}

sealed class DropdownEntry {
  const DropdownEntry();
}

final class DropdownAction extends DropdownEntry {
  const DropdownAction({
    required this.icon,
    required this.label,
    required this.onSelected,
    this.hint,
    this.tone = DropdownTone.plain,
  });

  final DesignIcons icon;
  final String label;
  final String? hint;
  final DropdownTone tone;
  final VoidCallback onSelected;
}

final class DropdownSeparator extends DropdownEntry {
  const DropdownSeparator();
}

class DesignDropdown extends StatefulWidget {
  const DesignDropdown({
    required this.placement,
    required this.entries,
    required this.anchorBuilder,
    super.key,
  });

  final DropdownPlacement placement;
  final List<DropdownEntry> entries;
  final DropdownAnchorBuilder anchorBuilder;

  @override
  State<DesignDropdown> createState() => _DesignDropdownState();
}

class _DesignDropdownState extends State<DesignDropdown> {
  final OverlayPortalController _menu = OverlayPortalController();
  final LayerLink _anchorLink = LayerLink();

  void _hideOnOutsideTap(PointerDownEvent event) {
    _menu.hide();
  }

  void _select(DropdownAction action) {
    _menu.hide();
    action.onSelected();
  }

  Widget _widgetFor(DropdownEntry entry) {
    return switch (entry) {
      DropdownAction() => DropdownItem(
        icon: entry.icon,
        label: entry.label,
        hint: entry.hint,
        tone: entry.tone,
        onPressed: () => _select(entry),
      ),
      DropdownSeparator() => const DesignDivider(),
    };
  }

  Widget _buildMenu(BuildContext context) {
    final placement = widget.placement;

    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: _anchorLink,
        showWhenUnlinked: false,
        targetAnchor: placement.targetAnchor,
        followerAnchor: placement.followerAnchor,
        offset: placement.offset,
        child: TapRegion(
          groupId: _anchorLink,
          onTapOutside: _hideOnOutsideTap,
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): _menu.hide,
            },
            child: Focus(
              autofocus: true,
              child: DropdownPanel(
                children: [
                  for (final entry in widget.entries) _widgetFor(entry),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _anchorLink,
      child: TapRegion(
        groupId: _anchorLink,
        child: OverlayPortal(
          controller: _menu,
          overlayChildBuilder: _buildMenu,
          child: widget.anchorBuilder(context, _menu),
        ),
      ),
    );
  }
}
