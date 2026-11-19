import 'package:flutter/widgets.dart';

import '../../shared/design/button_look.dart';
import '../../shared/design/design_button.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/icons/design_icons.dart';
import '../../shared/design/state_block.dart';
import '../../shared/import/file_picking.dart';
import '../../shared/import/generation_watch.dart';
import '../../shared/import/import_api.dart';
import '../../shared/import/import_dialog.dart';
import '../../shared/navigation/routes.dart';
import 'due_section.dart';
import 'folder_column.dart';
import 'folder_header.dart';
import 'folder_models.dart';
import 'folder_overview.dart';
import 'folders_api.dart';
import 'unit_actions.dart';
import 'unit_list.dart';
import 'unit_menu.dart';
import 'unit_presentation.dart';
import 'unit_routes.dart';
import 'unit_row.dart';
import 'units_head.dart';

const String _emptyTitle = 'Nothing here yet';
const String _emptyText =
    'Import a file, a link or a topic and Leffic will generate '
    'flashcards, a note and a test from it.';

class FolderView extends StatelessWidget {
  const FolderView({
    required this.folderId,
    required this.overview,
    required this.foldersApi,
    required this.importApi,
    required this.onChanged,
    super.key,
  });

  final String folderId;
  final FolderOverview overview;
  final FoldersApi foldersApi;
  final ImportApi importApi;
  final VoidCallback onChanged;

  Future<void> _open(BuildContext context, UnitRoute route) async {
    await Navigator.of(context)
        .pushNamed(route.name, arguments: route.arguments);

    onChanged();
  }

  Future<void> _import(BuildContext context) async {
    final isChanged = await showImportDialog(
      context: context,
      api: importApi,
      folderId: folderId,
      folderName: overview.listing.folderName,
      pickFile: pickSourceFileFromDisk,
      pollInterval: generationPollInterval,
    );

    if (isChanged) {
      onChanged();
    }
  }

  UnitRoute _folderRoute(String routeName) {
    final arguments = UnitArguments(
      id: folderId,
      name: overview.listing.folderName,
    );

    return (name: routeName, arguments: arguments);
  }

  Widget _header(List<Widget> actions) {
    return FolderHeader(
      ancestors: overview.listing.ancestors,
      folderName: overview.listing.folderName,
      actions: actions,
    );
  }

  Widget _unitRow(BuildContext context, UnitActions actions, int index) {
    final units = overview.listing.units;
    final unit = units[index];
    final unitRoute = routeForUnit(unit);
    final destinations = moveDestinationsFor(
      currentFolderId: folderId,
      units: units,
      movingUnit: unit,
    );

    return UnitRow(
      key: ValueKey(unit.id),
      unit: unit,
      meta: unitMetaLine(unit: unit, now: overview.loadedAt),
      dueCount: unitDueCount(unit),
      corners: unitRowCorners(index: index, count: units.length),
      onOpen: () => _open(context, unitRoute),
      menuEntries: unitMenuEntries(
        unit: unit,
        onReview: () => _open(context, unitRoute),
        onMove: () => actions.move(context, unit, destinations),
        onRename: () => actions.rename(context, unit),
        onDelete: () => actions.delete(context, unit),
      ),
    );
  }

  Widget _emptyFolder(BuildContext context, UnitActions actions) {
    return FolderColumn(
      children: [
        _header([
          NewFolderButton(onPressed: () => actions.createFolder(context)),
        ]),
        StateBlock(
          icon: DesignIcons.folderOpen,
          title: _emptyTitle,
          text: _emptyText,
          action: DesignButton(
            label: 'Import',
            icon: DesignIcons.aiImport,
            variant: ButtonVariant.primary,
            size: ButtonSize.large,
            onPressed: () => _import(context),
          ),
        ),
      ],
    );
  }

  Widget _filledFolder(BuildContext context, UnitActions actions) {
    final unitCount = overview.listing.units.length;

    return FolderColumn(
      children: [
        _header([
          NewFolderButton(onPressed: () => actions.createFolder(context)),
          ImportButton(onPressed: () => _import(context)),
        ]),
        DueSection(
          due: overview.due,
          onReviewFlashcards: () =>
              _open(context, _folderRoute(Routes.folderReview)),
          onTakeTest: () => _open(context, _folderRoute(Routes.folderTest)),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UnitsHead(count: unitCount),
            const SizedBox(height: Spacing.step3),
            UnitList(
              rows: [
                for (var index = 0; index < unitCount; index++)
                  _unitRow(context, actions, index),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = UnitActions(
      api: foldersApi,
      folderId: folderId,
      onChanged: onChanged,
    );

    if (overview.listing.units.isEmpty) {
      return _emptyFolder(context, actions);
    }

    return _filledFolder(context, actions);
  }
}
