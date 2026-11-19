import '../design/toast.dart';
import '../office/missing_libreoffice.dart';
import 'generation_progress.dart';
import 'generation_tasks.dart';

const String _generationWait = 'About a minute. You can keep working.';
const String _generationRefusal =
    'The source could not be processed. Try again.';
const String _uploadRefusal = 'The file could not be saved. Try again.';

ToastMessage generationProgressMessage(String sourceLabel) {
  return ToastMessage(
    tone: ToastTone.progress,
    title: 'Generating from $sourceLabel',
    detail: _generationWait,
  );
}

ToastMessage kindOutcomeMessage(GeneratedKindOutcome kindOutcome) {
  final kindLabel = kindOutcome.kind.label;

  if (kindOutcome.outcome == TaskOutcome.succeeded) {
    return ToastMessage(tone: ToastTone.success, title: '$kindLabel ready');
  }

  return ToastMessage(
    tone: ToastTone.failure,
    title: "Couldn't generate the ${kindLabel.toLowerCase()}",
    detail: _generationRefusal,
  );
}

ToastMessage generationFailureMessage(String sourceLabel, String reason) {
  return ToastMessage(
    tone: ToastTone.failure,
    title: "Couldn't generate from $sourceLabel",
    detail: reason,
  );
}

ToastMessage readingFailureMessage(String sourceLabel, String reason) {
  if (isMissingLibreOffice(reason)) {
    return missingLibreOfficeMessage;
  }

  return ToastMessage(
    tone: ToastTone.failure,
    title: "Couldn't read $sourceLabel",
    detail: reason,
  );
}

ToastMessage uploadProgressMessage(String fileName) {
  return ToastMessage(tone: ToastTone.progress, title: 'Uploading $fileName');
}

ToastMessage uploadSuccessMessage(String fileName) {
  return ToastMessage(tone: ToastTone.success, title: '$fileName uploaded');
}

ToastMessage uploadFailureMessage(String fileName) {
  return ToastMessage(
    tone: ToastTone.failure,
    title: "Couldn't upload $fileName",
    detail: _uploadRefusal,
  );
}
