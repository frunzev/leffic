import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../shared/design/button_look.dart';
import '../../shared/design/design_button.dart';
import '../../shared/design/design_colors.dart';
import '../../shared/design/design_dropdown.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/icons/design_icons.dart';
import 'folder_models.dart';
import 'unit_link.dart';

const Key _backgroundKey = ValueKey('unit row background');
const Color _transparent = Color(0x00000000);
const DropdownPlacement _menuPlacement = DropdownPlacement(
  targetAnchor: Alignment.bottomRight,
  followerAnchor: Alignment.topRight,
  offset: Offset(-Spacing.step2, -Spacing.step1),
);

class UnitRow extends StatefulWidget {
  const UnitRow({
    required this.unit,
    required this.meta,
    required this.dueCount,
    required this.corners,
    required this.onOpen,
    required this.menuEntries,
    super.key,
  });

  final FolderUnit unit;
  final String meta;
  final int dueCount;
  final BorderRadius corners;
  final VoidCallback onOpen;
  final List<DropdownEntry> menuEntries;

  @override
  State<UnitRow> createState() => _UnitRowState();
}

class _UnitRowState extends State<UnitRow> {
  bool _isHovered = false;

  void _enter(PointerEnterEvent event) {
    setState(() {
      _isHovered = true;
    });
  }

  void _exit(PointerExitEvent event) {
    setState(() {
      _isHovered = false;
    });
  }

  Widget _buildRow(BuildContext context, OverlayPortalController menu) {
    final unit = widget.unit;

    return Row(
      children: [
        Expanded(
          child: UnitLink(
            unit: unit,
            meta: widget.meta,
            dueCount: widget.dueCount,
            onOpen: widget.onOpen,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: Spacing.step2),
          child: DesignIconButton(
            icon: DesignIcons.dots,
            semanticLabel: 'More actions for ${unit.name}',
            variant: ButtonVariant.quiet,
            onPressed: menu.toggle,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hoverFill = DesignColors.of(context).hover;
    final fill = _isHovered ? hoverFill : _transparent;

    return MouseRegion(
      onEnter: _enter,
      onExit: _exit,
      child: DecoratedBox(
        key: _backgroundKey,
        decoration: BoxDecoration(color: fill, borderRadius: widget.corners),
        child: DesignDropdown(
          placement: _menuPlacement,
          entries: widget.menuEntries,
          anchorBuilder: _buildRow,
        ),
      ),
    );
  }
}
