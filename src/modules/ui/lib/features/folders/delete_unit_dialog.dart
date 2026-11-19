import 'package:flutter/widgets.dart';

import '../../shared/design/button_look.dart';
import '../../shared/design/design_button.dart';
import '../../shared/design/design_modal.dart';
import 'folder_models.dart';
import 'unit_presentation.dart';

const Widget _noBody = SizedBox.shrink();

Future<bool> confirmUnitDeletion({
  required BuildContext context,
  required FolderUnit unit,
}) async {
  final isConfirmed = await showDesignModal<bool>(
    context: context,
    builder: (context) => DeleteUnitDialog(unit: unit),
  );

  return isConfirmed ?? false;
}

class DeleteUnitDialog extends StatelessWidget {
  const DeleteUnitDialog({required this.unit, super.key});

  final FolderUnit unit;

  String _warning() {
    if (unit.type == UnitType.folder) {
      return 'Everything inside it is deleted too.';
    }

    return 'This cannot be undone.';
  }

  @override
  Widget build(BuildContext context) {
    return DesignModal(
      title: 'Delete ${unit.name}?',
      description: _warning(),
      body: _noBody,
      actions: [
        DesignButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        DesignButton(
          label: 'Delete ${unitNoun(unit.type)}',
          variant: ButtonVariant.danger,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
