import 'package:flutter/material.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/navigation/routes.dart';
import '../../shared/session/backend_scope.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/load_view.dart';
import 'note_document.dart';
import 'note_html_view.dart';
import 'note_opening.dart';
import 'note_view.dart';
import 'notes_api.dart';

class NotePage extends StatelessWidget {
  const NotePage({required this.arguments, super.key});

  final UnitArguments arguments;

  @override
  Widget build(BuildContext context) {
    final api = NotesApi(BackendScope.clientOf(context));
    final colors = DesignColors.of(context);

    return AppShell(
      selectedRoute: Routes.note,
      body: LoadView<OpenedNote>(
        load: () => openNoteWithProgress(api: api, noteId: arguments.id),
        builder: (context, opened, reload) => NoteView(
          note: opened.note,
          progress: opened.progress,
          body: NoteHtmlView(
            html: noteDocument(noteHtml: opened.note.content, colors: colors),
          ),
          markRead: () => api.markNoteRead(arguments.id),
        ),
      ),
    );
  }
}
