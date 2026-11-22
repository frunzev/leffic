import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/notes/note_opening.dart';
import 'package:leffic/features/notes/note_view.dart';
import 'package:leffic/features/notes/notes_api.dart';
import 'package:leffic/shared/widgets/load_view.dart';

import '../support/backend_fakes.dart';
import '../support/hosting.dart';
import 'requirement_world.dart';
import 'step_definition.dart';

const String _note = '/note';
const String _notesStats = '/notes-stats';
const String _reviewNote = '/review-note';
const String _readState = 'read';
const String _noteFolderId = 'folder-of-notes';

String _noteIdFor(String noteName) {
  return 'note-$noteName';
}

Future<void> _serveNote(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final [readState, noteName] = values;
  final isRead = readState == _readState;

  world.replies[_note] = answerWith({
    'content': '<p>Cells are the unit of life.</p>',
    'name': noteName,
    'read': isRead,
    'folder_id': _noteFolderId,
  });
  world.replies[_notesStats] = answerWith({
    'due': isRead ? 0 : 1,
    'read': isRead ? 1 : 0,
  });
  world.replies[_reviewNote] = answerWith({'note_id': _noteIdFor(noteName)});
}

class _NoteScreen {
  const _NoteScreen(this.api, this.noteId);

  final NotesApi api;
  final String noteId;

  Future<OpenedNote> load() {
    return openNoteWithProgress(api: api, noteId: noteId);
  }

  Future<void> markRead() {
    return api.markNoteRead(noteId);
  }

  Widget build(BuildContext context, OpenedNote opened, VoidCallback reload) {
    return NoteView(
      note: opened.note,
      progress: opened.progress,
      body: const SizedBox.shrink(),
      markRead: markRead,
    );
  }
}

Future<void> _openNote(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final screen = _NoteScreen(
    NotesApi(world.client()),
    _noteIdFor(values.single),
  );
  final page = LoadView<OpenedNote>(load: screen.load, builder: screen.build);

  await tester.pumpWidget(
    hostedWithBackend(client: world.client(), opened: [], child: page),
  );
  await tester.pumpAndSettle();
}

Future<void> _press(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  await tester.tap(find.text(values.single));
  await tester.pumpAndSettle();
}

Future<void> _checkNoteMarkedRead(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final markRequest = world.backend().sentTo(_reviewNote).single;

  expect(sentBody(markRequest), {'note_id': _noteIdFor(values.single)});
}

final List<StepDefinition> noteStepDefinitions = [
  StepDefinition(
    'Given',
    RegExp(r'^the backend has the (unread|read) note "(.+)"$'),
    _serveNote,
  ),
  StepDefinition(
    'When',
    RegExp(r'^I open the note "(.+)" in the app$'),
    _openNote,
  ),
  StepDefinition('When', RegExp(r'^I press "(.+)"$'), _press),
  StepDefinition(
    'Then',
    RegExp(r'^the backend received the note "(.+)" as read$'),
    _checkNoteMarkedRead,
  ),
];
