import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../shared/design/design_overlay.dart';
import '../../shared/navigation/routes.dart';
import '../../shared/session/backend_scope.dart';
import 'assessment_api.dart';
import 'assessment_review.dart';
import 'file_progress_memory.dart';

class FolderTestPage extends StatelessWidget {
  const FolderTestPage({required this.arguments, super.key});

  final UnitArguments arguments;

  @override
  Widget build(BuildContext context) {
    final api = AssessmentApi(BackendScope.clientOf(context));

    return Scaffold(
      body: DesignOverlay(
        title: 'Mixed test · ${arguments.name}',
        closeLabel: 'End test',
        onClose: () => Navigator.of(context).pop(),
        child: AssessmentReview(
          api: api,
          loadPage: (pageNumber) => api.folderItemsPage(
            folderId: arguments.id,
            pageNumber: pageNumber,
          ),
          loadMissedPage: (finishedSession, pageNumber) =>
              api.missedFolderItemsPage(
                folderId: arguments.id,
                finishedSession: finishedSession,
                pageNumber: pageNumber,
              ),
          memory: FileProgressMemory(
            scopeId: arguments.id,
            locateDirectory: getApplicationSupportDirectory,
          ),
        ),
      ),
    );
  }
}
