import 'package:flutter/widgets.dart';

import '../../shared/design/design_button.dart';
import '../../shared/design/design_colors.dart';
import '../../shared/design/design_dropdown.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_modal.dart';
import '../../shared/design/design_typography.dart';
import '../../shared/design/icons/design_icons.dart';
import 'folder_models.dart';

const String _nowhereToMove = 'There is no other folder to move it to.';

Future<String?> showMoveUnitDialog({
  required BuildContext context,
  required String unitName,
  required List<MoveDestination> destinations,
}) {
  return showDesignModal<String>(
    context: context,
    builder: (context) =>
        MoveUnitDialog(unitName: unitName, destinations: destinations),
  );
}

class MoveUnitDialog extends StatelessWidget {
  const MoveUnitDialog({
    required this.unitName,
    required this.destinations,
    super.key,
  });

  final String unitName;
  final List<MoveDestination> destinations;

  Widget _destinationList(BuildContext context) {
    if (destinations.isEmpty) {
      return Text(
        _nowhereToMove,
        style: textStyleForSize(TextSizes.small)
            .copyWith(color: DesignColors.of(context).inkSecondary),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final destination in destinations)
          DropdownItem(
            icon: DesignIcons.folder,
            label: destination.name,
            onPressed: () => Navigator.of(context).pop(destination.id),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DesignModal(
      title: 'Move $unitName',
      body: _destinationList(context),
      actions: [
        DesignButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
