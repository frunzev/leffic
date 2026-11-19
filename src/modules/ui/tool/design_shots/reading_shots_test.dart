import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/files/document_page_reports.dart';
import 'package:leffic/features/files/file_models.dart';
import 'package:leffic/features/files/file_page.dart';
import 'package:leffic/features/files/file_reader.dart';
import 'package:leffic/features/files/files_api.dart';
import 'package:leffic/features/notes/note_document.dart';
import 'package:leffic/features/notes/note_models.dart';
import 'package:leffic/features/notes/note_read_button.dart';
import 'package:leffic/features/notes/note_view.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/navigation/routes.dart';
import 'package:leffic/shared/session/backend_scope.dart';
import 'package:leffic/shared/widgets/app_shell.dart';
import 'package:leffic/shared/widgets/ask_panel_scope.dart';

import 'shot_backend.dart';
import 'shot_support.dart';

const double _designNoteBodyHeight = 524.75;
const int _designReadingWords = 760;
final String _noteContent = '<p>${'word ' * _designReadingWords}</p>';
const FileArguments _designFile = FileArguments(
  id: 'action-potentials',
  name: 'action-potentials.pdf',
  extension: 'pdf',
);
const StoredFileDetails _designFileDetails = StoredFileDetails(
  bookmarkedPage: 1,
  pageCount: 12,
  folderId: 'home',
  folderName: 'Home',
);
const NotesProgress _designFolderProgress = NotesProgress(read: 12, total: 13);
const NoteSource _designNoteSource = NoteSource(
  kind: 'file',
  reference: 'action-potentials.pdf',
);
const String _documentDirectory = String.fromEnvironment(
  'DESIGN_SHOTS_DIRECTORY',
);
const String _designNoteHtml =
    '<h2>Resting state</h2><p>A neuron at rest sits near −70 mV. The '
    'sodium–potassium pump moves three sodium ions out for every two '
    'potassium ions in, and potassium leak channels let potassium drift '
    'back out.</p><h2>Depolarisation</h2><p>When a stimulus pushes the '
    'membrane past roughly −55 mV, voltage-gated sodium channels open and '
    'sodium floods in. The membrane potential swings positive, peaking near '
    '+40 mV.</p><h2>Repolarisation</h2><ul><li>Sodium channels '
    'inactivate.</li><li>Voltage-gated potassium channels open.</li><li>'
    'Potassium leaves, driving the potential back down.</li></ul><h2>'
    'Refractory period</h2><p>Potassium channels close slowly, so the '
    'membrane briefly overshoots below rest. During this window the neuron '
    'cannot fire again, which is what keeps signals travelling in one '
    'direction.</p>';

Note _designNote(NoteReadState readState) {
  return Note(
    name: 'Action potentials',
    content: _noteContent,
    isRead: readState == NoteReadState.read,
    folderId: 'home',
    source: _designNoteSource,
  );
}

Widget _notePage(NoteReadState readState) {
  return AppShell(
    selectedRoute: Routes.note,
    body: NoteView(
      note: _designNote(readState),
      progress: _designFolderProgress,
      body: const SizedBox(height: _designNoteBodyHeight),
      markRead: () async {},
    ),
  );
}

Widget _blankDocument(DocumentPageReports pageReports) {
  return const SizedBox.expand();
}

class _FileReviewShot extends StatelessWidget {
  const _FileReviewShot();

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedRoute: Routes.file,
      body: FileReader(
        api: FilesApi(BackendScope.clientOf(context)),
        file: _designFile,
        details: _designFileDetails,
        documentBuilder: _blankDocument,
        onGenerateStudyUnits: () {},
        onClose: () {},
      ),
    );
  }
}

Widget _fileReviewPage() {
  return BackendScope(
    link: shotBackendLink(shotNeverReply),
    child: const _FileReviewShot(),
  );
}

Widget _fileLoadingPage() {
  return BackendScope(
    link: shotBackendLink(shotNeverReply),
    child: const FilePage(arguments: _designFile),
  );
}

Future<void> _shoot(
  WidgetTester tester,
  Brightness brightness,
  Widget page,
  String slug,
) async {
  await pumpShotApp(
    tester,
    brightness: brightness,
    askPanel: AskPanelController(),
    panel: surfacePanelFor(brightness),
    home: page,
  );
  await tester.pump();

  await saveShot(tester, slug, brightness);
  releaseDesktopWindow();
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('notes review in ${brightness.name}', (tester) async {
      await _shoot(
        tester,
        brightness,
        _notePage(NoteReadState.unread),
        'notes-review',
      );
    });

    testWidgets('notes review read in ${brightness.name}', (tester) async {
      await _shoot(
        tester,
        brightness,
        _notePage(NoteReadState.read),
        'notes-review-read',
      );
    });

    testWidgets('file review in ${brightness.name}', (tester) async {
      await _shoot(tester, brightness, _fileReviewPage(), 'file-review');
    });

    testWidgets('file loading in ${brightness.name}', (tester) async {
      await _shoot(tester, brightness, _fileLoadingPage(), 'file-loading');
    });

    test('note document in ${brightness.name}', () {
      final document = noteDocument(
        noteHtml: _designNoteHtml,
        colors: DesignColors.forBrightness(brightness),
      );

      File('$_documentDirectory/note-document-${brightness.name}.html')
          .writeAsStringSync(document);
    });
  }
}
