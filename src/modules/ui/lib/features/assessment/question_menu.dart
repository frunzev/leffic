import 'package:flutter/material.dart';

import '../../shared/design/button_look.dart';
import '../../shared/design/design_button.dart';
import '../../shared/design/design_dropdown.dart';
import '../../shared/design/icons/design_icons.dart';

class QuestionMenu extends StatelessWidget {
  const QuestionMenu({required this.onEdit, super.key});

  final VoidCallback onEdit;

  Widget _buildActionsButton(
    BuildContext context,
    OverlayPortalController menu,
  ) {
    return DesignIconButton(
      icon: DesignIcons.dots,
      semanticLabel: 'Actions for this question',
      variant: ButtonVariant.quiet,
      onPressed: menu.toggle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DesignDropdown(
      placement: DropdownPlacement.belowEnd,
      entries: [
        DropdownAction(
          icon: DesignIcons.settings,
          label: 'Edit question',
          onSelected: onEdit,
        ),
      ],
      anchorBuilder: _buildActionsButton,
    );
  }
}
