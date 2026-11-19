import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../design/design_metrics.dart';
import 'chosen_file.dart';
import 'dropzone.dart';
import 'import_source.dart';
import 'page_range_fields.dart';

class FileSourcePanel extends StatelessWidget {
  const FileSourcePanel({
    required this.file,
    required this.firstPage,
    required this.lastPage,
    required this.onBrowse,
    required this.onRemove,
    required this.onTyped,
    super.key,
  });

  final UploadedFile? file;
  final TextEditingController firstPage;
  final TextEditingController lastPage;
  final VoidCallback onBrowse;
  final VoidCallback onRemove;
  final ValueChanged<String> onTyped;

  @override
  Widget build(BuildContext context) {
    final chosenFile = file;

    if (chosenFile == null) {
      return Dropzone(onBrowse: onBrowse);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spacing.step3,
      children: [
        ChosenFile(file: chosenFile, onRemove: onRemove),
        if (isPagedFileName(chosenFile.name))
          PageRangeFields(
            firstPage: firstPage,
            lastPage: lastPage,
            onChanged: onTyped,
          ),
      ],
    );
  }
}
