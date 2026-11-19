import 'package:flutter/material.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';
import 'note_card.dart';
import 'note_foot.dart';
import 'note_models.dart';
import 'note_read_button.dart';
import 'reading_time.dart';

const double _titleLetterSpacingInEm = -0.01;

class NoteView extends StatelessWidget {
  const NoteView({
    required this.note,
    required this.progress,
    required this.body,
    required this.markRead,
    super.key,
  });

  final Note note;
  final NotesProgress progress;
  final Widget body;
  final Future<void> Function() markRead;

  String _metaLabel() {
    final readingTime = readingTimeLabel(note.content);
    final source = note.source;

    if (source == null) {
      return readingTime;
    }

    return '$readingTime · generated from ${source.origin}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);
    final divider = BorderSide(color: colors.line);
    final initialReadState = note.isRead
        ? NoteReadState.read
        : NoteReadState.unread;

    return NoteCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.step4,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: Spacing.step4),
            decoration: BoxDecoration(border: Border(bottom: divider)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Spacing.step2,
              children: [
                Text(
                  note.name,
                  style: textStyleForSize(
                    TextSizes.extraLarge,
                    addedLetterSpacingInEm: _titleLetterSpacingInEm,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  _metaLabel(),
                  style: textStyleForSize(TextSizes.small)
                      .copyWith(color: colors.inkTertiary),
                ),
              ],
            ),
          ),
          Flexible(child: body),
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(top: Spacing.step4),
            decoration: BoxDecoration(border: Border(top: divider)),
            child: NoteFoot(
              initialReadState: initialReadState,
              initialProgress: progress,
              markRead: markRead,
            ),
          ),
        ],
      ),
    );
  }
}
