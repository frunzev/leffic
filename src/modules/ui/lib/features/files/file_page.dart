import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../shared/import/file_picking.dart';
import '../../shared/import/generation_watch.dart';
import '../../shared/import/import_api.dart';
import '../../shared/import/import_dialog.dart';
import '../../shared/navigation/routes.dart';
import '../../shared/session/backend_scope.dart';
import '../../shared/widgets/app_shell.dart';
import 'file_models.dart';
import 'file_opener.dart';
import 'file_opening.dart';
import 'file_reader.dart';
import 'files_api.dart';
import 'pdf_view.dart';

class FilePage extends StatelessWidget {
  const FilePage({required this.arguments, super.key});

  final FileArguments arguments;

  Future<void> _generateStudyUnits(
    BuildContext context,
    StoredFileDetails details,
  ) async {
    await showStoredFileImportDialog(
      context: context,
      api: ImportApi(BackendScope.clientOf(context)),
      fileId: arguments.id,
      fileName: arguments.name,
      folderId: details.folderId,
      folderName: details.folderName,
      pickFile: pickSourceFileFromDisk,
      pollInterval: generationPollInterval,
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = FilesApi(BackendScope.clientOf(context));

    return AppShell(
      selectedRoute: Routes.file,
      body: FileOpener(
        fileName: arguments.name,
        open: () => openFile(
          api: api,
          file: arguments,
          findTemporaryDirectory: getTemporaryDirectory,
        ),
        builder: (context, opened) => FileReader(
          api: api,
          file: arguments,
          details: opened.details,
          documentBuilder: (pageReports) =>
              PdfView(pdf: opened.pdf, pageReports: pageReports),
          onGenerateStudyUnits: () =>
              _generateStudyUnits(context, opened.details),
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
