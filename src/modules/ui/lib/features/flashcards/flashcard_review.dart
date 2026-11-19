import 'package:flutter/material.dart';

import '../../shared/widgets/load_view.dart';
import '../../shared/widgets/review_stage.dart';
import 'flashcard_models.dart';
import 'flashcard_session.dart';
import 'flashcards_api.dart';

class FlashcardReview extends StatelessWidget {
  const FlashcardReview({required this.api, required this.loadDue, super.key});

  final FlashcardsApi api;
  final DueFlashcardsLoader loadDue;

  @override
  Widget build(BuildContext context) {
    return ReviewStage(
      child: LoadView<DueFlashcards>(
        load: loadDue,
        builder: (context, firstDue, reload) =>
            FlashcardSession(api: api, loadDue: loadDue, firstDue: firstDue),
      ),
    );
  }
}
