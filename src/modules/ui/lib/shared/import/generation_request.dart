import '../api/json_reading.dart';
import 'generation_choices.dart';
import 'import_source.dart';

class GenerationRequest {
  const GenerationRequest({
    required this.text,
    required this.folderId,
    required this.source,
    required this.choices,
  });

  final String text;
  final String folderId;
  final ImportSource source;
  final GenerationChoices choices;

  JsonObject toJson() {
    return {
      'text': text,
      'folder_id': folderId,
      'source_kind': source.sourceKind,
      'source_reference': source.reference,
      ...choices.toJson(),
    };
  }
}
