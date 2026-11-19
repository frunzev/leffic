import 'package:flutter/material.dart';

import '../design/design_modal.dart';
import '../design/toast_host.dart';
import 'file_picking.dart';
import 'generation_request.dart';
import 'import_announcements.dart';
import 'import_api.dart';
import 'import_modal.dart';
import 'import_plan.dart';
import 'import_source.dart';
import 'source_text_reader.dart';
import 'stored_source_files.dart';

typedef ImportDestination = ({String folderId, String folderName});

Future<bool> showImportDialog({
  required BuildContext context,
  required ImportApi api,
  required String folderId,
  required String folderName,
  required SourceFilePicker pickFile,
  required Duration pollInterval,
}) {
  return _showImportModal(
    context: context,
    api: api,
    destination: (folderId: folderId, folderName: folderName),
    pickFile: pickFile,
    pollInterval: pollInterval,
    sourceToRead: null,
  );
}

Future<bool> showStoredFileImportDialog({
  required BuildContext context,
  required ImportApi api,
  required String fileId,
  required String fileName,
  required String folderId,
  required String folderName,
  required SourceFilePicker pickFile,
  required Duration pollInterval,
}) {
  return _showImportModal(
    context: context,
    api: api,
    destination: (folderId: folderId, folderName: folderName),
    pickFile: pickFile,
    pollInterval: pollInterval,
    sourceToRead: StoredFileImportSource(fileId: fileId, fileName: fileName),
  );
}

Future<bool> _showImportModal({
  required BuildContext context,
  required ImportApi api,
  required ImportDestination destination,
  required SourceFilePicker pickFile,
  required Duration pollInterval,
  required ImportSource? sourceToRead,
}) async {
  final toasts = ToastHost.of(context);
  final storedFiles = StoredSourceFiles(
    api: api,
    folderId: destination.folderId,
  );
  final reader = SourceTextReader(api: api, storedFiles: storedFiles);

  final plan = await showDesignModal<ImportPlan>(
    context: context,
    builder: (modalContext) => ImportModal(
      folderName: destination.folderName,
      pickFile: pickFile,
      readSourceText: reader.read,
      sourceToRead: sourceToRead,
    ),
  );

  final carryingOut = switch (plan) {
    null => Future<void>.value(),
    UploadPlan(:final file) => announceUpload(
      toasts: toasts,
      storedFiles: storedFiles,
      file: file,
    ),
    GenerationPlan() => announceGeneration(
      toasts: toasts,
      api: api,
      request: GenerationRequest(
        text: plan.text,
        folderId: destination.folderId,
        source: plan.source,
        choices: plan.choices,
      ),
      pollInterval: pollInterval,
    ),
  };

  await carryingOut;

  final isFolderChanged = plan != null || storedFiles.isAnyStored;

  return isFolderChanged && context.mounted;
}
