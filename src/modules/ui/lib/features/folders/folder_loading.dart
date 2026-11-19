import 'package:flutter/widgets.dart';

import '../../shared/navigation/routes.dart';
import 'folder_column.dart';
import 'folder_header.dart';
import 'folder_models.dart';
import 'folder_skeleton.dart';

class FolderLoading extends StatelessWidget {
  const FolderLoading({
    required this.folderId,
    required this.folderName,
    required this.onNewFolder,
    super.key,
  });

  final String folderId;
  final String folderName;
  final VoidCallback onNewFolder;

  List<FolderAncestor> _knownAncestors() {
    if (folderId == homeFolderId) {
      return const [];
    }

    return const [homeAncestor];
  }

  @override
  Widget build(BuildContext context) {
    return FolderColumn(
      children: [
        FolderHeader(
          ancestors: _knownAncestors(),
          folderName: folderName,
          actions: [NewFolderButton(onPressed: onNewFolder)],
        ),
        const DueSkeleton(),
        const UnitsSkeleton(),
      ],
    );
  }
}
