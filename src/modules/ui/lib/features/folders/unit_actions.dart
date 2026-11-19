import 'package:flutter/widgets.dart';

import '../../shared/api/api_error.dart';
import '../../shared/design/toast.dart';
import '../../shared/design/toast_host.dart';
import 'delete_unit_dialog.dart';
import 'folder_models.dart';
import 'folders_api.dart';
import 'move_unit_dialog.dart';
import 'name_prompt_dialog.dart';

typedef FolderChange = Future<void> Function();

const NamePrompt _newFolderPrompt = NamePrompt(
  title: 'Create a folder',
  description: 'Folders keep related study units together.',
  fieldLabel: 'Folder name',
  placeholder: 'e.g. Neuroscience',
  confirmLabel: 'Create',
);

NamePrompt _renamePrompt(FolderUnit unit) {
  return NamePrompt(
    title: 'Rename',
    fieldLabel: 'Name',
    confirmLabel: 'Save name',
    initialName: unit.name,
  );
}

class UnitActions {
  const UnitActions({
    required this.api,
    required this.folderId,
    required this.onChanged,
  });

  final FoldersApi api;
  final String folderId;
  final VoidCallback onChanged;

  Future<void> createFolder(BuildContext context) async {
    final toasts = ToastHost.of(context);
    final name = await showNamePrompt(
      context: context,
      prompt: _newFolderPrompt,
    );

    if (name == null) {
      return;
    }

    await _apply(
      toasts,
      () => api.createFolder(parentFolderId: folderId, name: name),
    );
  }

  Future<void> rename(BuildContext context, FolderUnit unit) async {
    final toasts = ToastHost.of(context);
    final name = await showNamePrompt(
      context: context,
      prompt: _renamePrompt(unit),
    );

    if (name == null) {
      return;
    }

    await _apply(toasts, () => api.renameUnit(unit: unit, name: name));
  }

  Future<void> move(
    BuildContext context,
    FolderUnit unit,
    List<MoveDestination> destinations,
  ) async {
    final toasts = ToastHost.of(context);
    final destinationId = await showMoveUnitDialog(
      context: context,
      unitName: unit.name,
      destinations: destinations,
    );

    if (destinationId == null) {
      return;
    }

    await _apply(
      toasts,
      () => api.moveUnit(unit: unit, destinationFolderId: destinationId),
    );
  }

  Future<void> delete(BuildContext context, FolderUnit unit) async {
    final toasts = ToastHost.of(context);
    final isConfirmed = await confirmUnitDeletion(context: context, unit: unit);

    if (!isConfirmed) {
      return;
    }

    await _apply(toasts, () => api.deleteUnit(unit));
  }

  Future<void> _apply(ToastHostState toasts, FolderChange change) async {
    try {
      await change();
    } on ApiError catch (failure) {
      toasts.show(ToastMessage(tone: ToastTone.failure, title: failure.detail));
      return;
    }

    onChanged();
  }
}
