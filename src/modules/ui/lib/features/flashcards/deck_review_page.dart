import 'package:flutter/material.dart';

import '../../shared/navigation/routes.dart';
import '../../shared/session/backend_scope.dart';
import '../../shared/widgets/app_shell.dart';
import 'flashcard_review.dart';
import 'flashcards_api.dart';

class DeckReviewPage extends StatelessWidget {
  const DeckReviewPage({required this.arguments, super.key});

  final UnitArguments arguments;

  @override
  Widget build(BuildContext context) {
    final api = FlashcardsApi(BackendScope.clientOf(context));

    return AppShell(
      selectedRoute: Routes.deckReview,
      body: FlashcardReview(
        api: api,
        loadDue: () => api.deckFlashcards(arguments.id),
      ),
    );
  }
}
