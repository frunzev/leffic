import 'package:flutter/widgets.dart';

import '../../shared/import/import_api.dart';
import '../../shared/navigation/routes.dart';
import '../../shared/session/backend_scope.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/load_view.dart';
import 'folder_loading.dart';
import 'folder_models.dart';
import 'folder_overview.dart';
import 'folder_view.dart';
import 'folders_api.dart';
import 'unit_actions.dart';

class FolderPage extends StatelessWidget {
  const FolderPage({required this.arguments, super.key});

  final UnitArguments arguments;

  @override
  Widget build(BuildContext context) {
    final client = BackendScope.clientOf(context);
    final states = _FolderStates(
      arguments: arguments,
      foldersApi: FoldersApi(client),
      importApi: ImportApi(client),
    );

    return AppShell(
      selectedRoute: Routes.folder,
      body: LoadView<FolderOverview>(
        load: states.load,
        placeholder: states.buildLoading,
        builder: states.buildLoaded,
      ),
    );
  }
}

class _FolderStates {
  const _FolderStates({
    required this.arguments,
    required this.foldersApi,
    required this.importApi,
  });

  final UnitArguments arguments;
  final FoldersApi foldersApi;
  final ImportApi importApi;

  String _knownFolderName() {
    if (arguments.id == homeFolderId) {
      return homeFolderName;
    }

    return arguments.name;
  }

  Future<FolderOverview> load() {
    return loadFolderOverview(api: foldersApi, folderId: arguments.id);
  }

  Widget buildLoading(BuildContext context, VoidCallback reload) {
    final actions = UnitActions(
      api: foldersApi,
      folderId: arguments.id,
      onChanged: reload,
    );

    return FolderLoading(
      folderId: arguments.id,
      folderName: _knownFolderName(),
      onNewFolder: () => actions.createFolder(context),
    );
  }

  Widget buildLoaded(
    BuildContext context,
    FolderOverview overview,
    VoidCallback reload,
  ) {
    return FolderView(
      folderId: arguments.id,
      overview: overview,
      foldersApi: foldersApi,
      importApi: importApi,
      onChanged: reload,
    );
  }
}
