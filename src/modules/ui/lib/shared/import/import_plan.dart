import '../api/api_client.dart';
import 'generation_choices.dart';
import 'import_source.dart';

sealed class ImportPlan {
  const ImportPlan();
}

final class GenerationPlan extends ImportPlan {
  const GenerationPlan({
    required this.source,
    required this.text,
    required this.choices,
  });

  final ImportSource source;
  final String text;
  final GenerationChoices choices;
}

final class UploadPlan extends ImportPlan {
  const UploadPlan({required this.file});

  final UploadedFile file;
}
