import 'package:flutter/material.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';
import 'note_models.dart';
import 'note_read_button.dart';

class NoteFoot extends StatefulWidget {
  const NoteFoot({
    required this.initialReadState,
    required this.initialProgress,
    required this.markRead,
    super.key,
  });

  final NoteReadState initialReadState;
  final NotesProgress initialProgress;
  final Future<void> Function() markRead;

  @override
  State<NoteFoot> createState() => _NoteFootState();
}

class _NoteFootState extends State<NoteFoot> {
  late NotesProgress _progress = widget.initialProgress;

  Future<void> _markRead() async {
    await widget.markRead();

    if (mounted) {
      setState(() => _progress = _progress.afterOneMoreRead());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.step3,
      runSpacing: Spacing.step3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        NoteReadButton(
          initialState: widget.initialReadState,
          markRead: _markRead,
        ),
        Text(
          'Read ${_progress.read} of ${_progress.total} notes in this folder.',
          style: textStyleForSize(TextSizes.small)
              .copyWith(color: DesignColors.of(context).inkTertiary),
        ),
      ],
    );
  }
}
