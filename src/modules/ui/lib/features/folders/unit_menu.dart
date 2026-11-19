import 'package:flutter/widgets.dart';

import '../../shared/design/design_dropdown.dart';
import '../../shared/design/icons/design_icons.dart';
import 'folder_models.dart';
import 'unit_presentation.dart';

const Set<UnitType> _reviewableTypes = {UnitType.flashcardDeck, UnitType.test};

List<DropdownEntry> unitMenuEntries({
  required FolderUnit unit,
  required VoidCallback onReview,
  required VoidCallback onMove,
  required VoidCallback onRename,
  required VoidCallback onDelete,
}) {
  return [
    if (_reviewableTypes.contains(unit.type))
      DropdownAction(
        icon: DesignIcons.study,
        label: 'Review now',
        onSelected: onReview,
      ),
    DropdownAction(
      icon: DesignIcons.folderOpen,
      label: 'Move to folder',
      onSelected: onMove,
    ),
    DropdownAction(
      icon: DesignIcons.settings,
      label: 'Rename',
      onSelected: onRename,
    ),
    const DropdownSeparator(),
    DropdownAction(
      icon: DesignIcons.trash,
      label: 'Delete ${unitNoun(unit.type)}',
      tone: DropdownTone.danger,
      onSelected: onDelete,
    ),
  ];
}
