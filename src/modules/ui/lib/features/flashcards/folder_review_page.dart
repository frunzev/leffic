import 'package:flutter/material.dart';

import '../../shared/design/design_overlay.dart';
import '../../shared/navigation/routes.dart';
import '../../shared/session/backend_scope.dart';
import 'flashcard_review.dart';
import 'flashcards_api.dart';

class FolderReviewPage extends StatelessWidget {
  const FolderReviewPage({required this.arguments, super.key});

  final UnitArguments arguments;

  @override
  Widget build(BuildContext context) {
    final api = FlashcardsApi(BackendScope.clientOf(context));

    return Scaffold(
      body: DesignOverlay(
        title: 'Mixed review · ${arguments.name}',
        closeLabel: 'End review',
        onClose: () => Navigator.of(context).pop(),
        child: FlashcardReview(
          api: api,
          loadDue: () => api.folderFlashcards(arguments.id),
        ),
      ),
    );
  }
}
