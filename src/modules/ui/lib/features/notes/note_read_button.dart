import 'package:flutter/material.dart';

import '../../shared/design/button_look.dart';
import '../../shared/design/design_button.dart';
import '../../shared/design/icons/design_icons.dart';
import '../../shared/design/toast.dart';
import '../../shared/design/toast_host.dart';

enum NoteReadState { unread, saving, read }

const ToastMessage _markingFailure = ToastMessage(
  tone: ToastTone.failure,
  title: "Couldn't mark the note as read",
  detail: 'The note stayed in your due list. Try again.',
);

class NoteReadButton extends StatefulWidget {
  const NoteReadButton({
    required this.initialState,
    required this.markRead,
    super.key,
  });

  final NoteReadState initialState;
  final Future<void> Function() markRead;

  @override
  State<NoteReadButton> createState() => _NoteReadButtonState();
}

class _NoteReadButtonState extends State<NoteReadButton> {
  late NoteReadState _readState = widget.initialState;

  void _show(NoteReadState readState) {
    if (!mounted) {
      return;
    }

    setState(() => _readState = readState);
  }

  void _showMarkingFailure() {
    if (!mounted) {
      return;
    }

    setState(() => _readState = NoteReadState.unread);
    ToastHost.of(context).show(_markingFailure);
  }

  Future<void> _markRead() async {
    _show(NoteReadState.saving);

    try {
      await widget.markRead();
    } on Exception {
      _showMarkingFailure();
      return;
    }

    _show(NoteReadState.read);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_readState) {
      NoteReadState.unread => DesignButton(
        label: 'Mark as read',
        icon: DesignIcons.check,
        variant: ButtonVariant.primary,
        onPressed: _markRead,
      ),
      NoteReadState.saving => const DesignButton(
        label: 'Marking…',
        icon: DesignIcons.check,
        variant: ButtonVariant.primary,
        onPressed: null,
      ),
      NoteReadState.read => const DesignButton(
        label: 'Marked as read',
        icon: DesignIcons.success,
        variant: ButtonVariant.done,
        onPressed: null,
      ),
    };
  }
}
