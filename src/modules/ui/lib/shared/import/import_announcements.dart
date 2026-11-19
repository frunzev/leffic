import '../api/api_client.dart';
import '../design/toast_host.dart';
import 'generation_progress.dart';
import 'generation_request.dart';
import 'generation_watch.dart';
import 'import_api.dart';
import 'import_messages.dart';
import 'stored_source_files.dart';

Future<void> announceGeneration({
  required ToastHostState toasts,
  required ImportApi api,
  required GenerationRequest request,
  required Duration pollInterval,
}) async {
  final sourceLabel = request.source.label;
  final progressToast = toasts.show(generationProgressMessage(sourceLabel));

  try {
    final tasks = await api.generateStudyUnits(request);
    final snapshots = watchGeneration(
      api: api,
      tasks: tasks,
      pollInterval: pollInterval,
    );

    await for (final kindOutcome in announcedKindOutcomes(snapshots)) {
      toasts.show(kindOutcomeMessage(kindOutcome));
    }
  } on Exception catch (failure) {
    toasts.show(generationFailureMessage(sourceLabel, '$failure'));
  } finally {
    toasts.dismiss(progressToast);
  }
}

Future<void> announceUpload({
  required ToastHostState toasts,
  required StoredSourceFiles storedFiles,
  required UploadedFile file,
}) async {
  final progressToast = toasts.show(uploadProgressMessage(file.name));

  try {
    await storedFiles.store(file);
    toasts.show(uploadSuccessMessage(file.name));
  } on Exception {
    toasts.show(uploadFailureMessage(file.name));
  } finally {
    toasts.dismiss(progressToast);
  }
}
