import 'package:flutter/material.dart';

import '../../shared/api/api_error.dart';
import '../../shared/api/chat_api.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/toast.dart';
import '../../shared/design/toast_host.dart';
import 'card_menu.dart';
import 'delete_card_dialog.dart';
import 'face_views.dart';
import 'flashcard_card.dart';
import 'flashcard_editor_dialog.dart';
import 'flashcard_models.dart';
import 'flashcards_api.dart';
import 'mnemonic_dialog.dart';
import 'rating_buttons.dart';
import 'review_finished_view.dart';
import 'review_meter.dart';
import 'review_queue.dart';
import 'review_shortcuts.dart';
import 'show_answer_button.dart';

typedef QueueChange = Future<ReviewQueue> Function();

class FlashcardSession extends StatefulWidget {
  const FlashcardSession({
    required this.api,
    required this.loadDue,
    required this.firstDue,
    super.key,
  });

  final FlashcardsApi api;
  final DueFlashcardsLoader loadDue;
  final DueFlashcards firstDue;

  @override
  State<FlashcardSession> createState() => _FlashcardSessionState();
}

class _FlashcardSessionState extends State<FlashcardSession> {
  late ReviewQueue _queue = ReviewQueue.startingWith(widget.firstDue);
  bool _isAnswerShown = false;

  void _revealAnswer() {
    setState(() => _isAnswerShown = true);
  }

  void _hideAnswer() {
    setState(() => _isAnswerShown = false);
  }

  Future<void> _rate(Flashcard card, FlashcardRating rating) async {
    _hideAnswer();

    await _changeQueue("Couldn't save your rating", () async {
      final outcome = await widget.api.review(
        flashcardId: card.id,
        rating: rating,
      );
      final reviewed = _queue.afterReview(outcome, now: DateTime.now());

      return _refilledWhenEmpty(reviewed);
    });
  }

  Future<void> _edit(Flashcard card) async {
    final face = await showFlashcardEditor(context: context, face: card.face);

    if (face == null) {
      return;
    }

    await _changeQueue("Couldn't save the card", () async {
      await widget.api.updateFace(flashcardId: card.id, face: face);

      return _queue.withCurrentFace(face);
    });
  }

  Future<void> _delete(Flashcard card) async {
    final isConfirmed = await confirmCardDeletion(
      context,
      question: card.face.question,
    );

    if (!isConfirmed) {
      return;
    }

    _hideAnswer();

    await _changeQueue("Couldn't delete the card", () async {
      await widget.api.delete(card.id);

      return _refilledWhenEmpty(_queue.afterDeletion());
    });
  }

  Future<ReviewQueue> _refilledWhenEmpty(ReviewQueue queue) async {
    if (queue.current != null) {
      return queue;
    }

    return queue.refilledWith(await widget.loadDue());
  }

  Future<void> _changeQueue(String failureTitle, QueueChange change) async {
    final toasts = ToastHost.of(context);
    final ReviewQueue changedQueue;

    try {
      changedQueue = await change();
    } on ApiError catch (failure) {
      toasts.show(
        ToastMessage(
          tone: ToastTone.failure,
          title: failureTitle,
          detail: failure.detail,
        ),
      );
      return;
    }

    if (mounted) {
      setState(() => _queue = changedQueue);
    }
  }

  Widget _reviewOf(Flashcard card) {
    final face = card.face;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spacing.step4,
      children: [
        if (_queue.totalToReview > 0) ReviewMeter(queue: _queue),
        Flexible(
          child: FlashcardCard(
            faces: [
              FlashcardPromptView(face: face),
              if (_isAnswerShown) FlashcardAnswerView(face: face),
            ],
            menu: CardMenu(
              onMnemonic: () => showMnemonicDialog(
                context: context,
                chatApi: ChatApi(widget.api.client),
                face: face,
              ),
              onEdit: () => _edit(card),
              onDelete: () => _delete(card),
            ),
          ),
        ),
        if (_isAnswerShown)
          RatingButtons(
            loadIntervals: () =>
                widget.api.ratingIntervals(card.schedulingState),
            onRate: (rating) => _rate(card, rating),
          )
        else
          ShowAnswerButton(onPressed: _revealAnswer),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = _queue.current;

    if (card == null) {
      return ReviewFinishedView(
        onBackToFolder: () => Navigator.of(context).pop(),
      );
    }

    return ReviewShortcuts(
      onReveal: _isAnswerShown ? null : _revealAnswer,
      onRate: _isAnswerShown ? (rating) => _rate(card, rating) : null,
      child: _reviewOf(card),
    );
  }
}
