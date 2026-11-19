import 'package:flutter/material.dart';

import '../../shared/design/button_look.dart';
import '../../shared/design/design_button.dart';
import '../../shared/design/design_dropdown.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/icons/design_icons.dart';

class CardMenu extends StatelessWidget {
  const CardMenu({
    required this.onMnemonic,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final VoidCallback onMnemonic;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Widget _buildActionsButton(
    BuildContext context,
    OverlayPortalController menu,
  ) {
    return DesignIconButton(
      icon: DesignIcons.dots,
      semanticLabel: 'Actions for this card',
      variant: ButtonVariant.quiet,
      onPressed: menu.toggle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Spacing.step1,
      children: [
        DesignIconButton(
          icon: DesignIcons.mnemonic,
          semanticLabel: 'Ask for a way to memorise this card',
          variant: ButtonVariant.quiet,
          onPressed: onMnemonic,
        ),
        DesignDropdown(
          placement: DropdownPlacement.belowEnd,
          entries: [
            DropdownAction(
              icon: DesignIcons.settings,
              label: 'Edit card',
              onSelected: onEdit,
            ),
            const DropdownSeparator(),
            DropdownAction(
              icon: DesignIcons.trash,
              label: 'Delete card',
              tone: DropdownTone.danger,
              onSelected: onDelete,
            ),
          ],
          anchorBuilder: _buildActionsButton,
        ),
      ],
    );
  }
}
