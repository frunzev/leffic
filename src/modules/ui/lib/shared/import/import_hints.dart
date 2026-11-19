import 'generation_choices.dart';
import 'import_draft.dart';
import 'import_source.dart';

const String _nothingChosen = 'Choose something to generate.';
const String _noTextKept = 'Keep some text to generate from.';

String? sourceStepHint({
  required DraftReading reading,
  required ImportSourceKind kind,
  required GenerationChoices choices,
}) {
  if (reading is SourceMissing) {
    return reading.reason;
  }

  final isGeneratedHere = kind == ImportSourceKind.text;

  if (isGeneratedHere && !choices.isAnythingRequested) {
    return _nothingChosen;
  }

  return null;
}

String? reviewStepHint({
  required String reviewedText,
  required GenerationChoices choices,
}) {
  if (reviewedText.trim().isEmpty) {
    return _noTextKept;
  }

  if (!choices.isAnythingRequested) {
    return _nothingChosen;
  }

  return null;
}
