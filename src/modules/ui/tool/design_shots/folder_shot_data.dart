import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:leffic/features/folders/due_models.dart';
import 'package:leffic/features/folders/folder_models.dart';
import 'package:leffic/features/folders/folder_overview.dart';
import 'package:leffic/features/folders/folder_view.dart';
import 'package:leffic/features/folders/folders_api.dart';
import 'package:leffic/features/folders/unit_details.dart';
import 'package:leffic/shared/api/api_client.dart';
import 'package:leffic/shared/import/import_api.dart';
import 'package:leffic/shared/navigation/routes.dart';
import 'package:leffic/shared/widgets/app_shell.dart';

import 'shot_backend.dart';

const int _refusedStatus = 503;

final DateTime shotLoadedAt = DateTime(2026, 11, 18, 12);

Future<http.Response> _refuse(http.Request request) async {
  return http.Response('', _refusedStatus);
}

final ApiClient shotClient = shotApiClient(_refuse);

void _ignoreChange() {}

Widget shotFolderPage(String folderId, FolderOverview overview) {
  return AppShell(
    selectedRoute: Routes.folder,
    body: FolderView(
      folderId: folderId,
      overview: overview,
      foldersApi: FoldersApi(shotClient),
      importApi: ImportApi(shotClient),
      onChanged: _ignoreChange,
    ),
  );
}

typedef _DesignUnit = ({
  String id,
  String name,
  UnitType type,
  int daysAgo,
  UnitDetails details,
});

const String _homeFolderUuid = 'home-folder-uuid';
const String _pdfExtension = 'pdf';
const int _designPdfBytes = 1200000;

DateTime _daysBeforeShot(int days) {
  return shotLoadedAt.subtract(Duration(days: days));
}

FolderUnit _unit(_DesignUnit design) {
  final isFile = design.type == UnitType.file;

  return FolderUnit(
    id: design.id,
    name: design.name,
    type: design.type,
    createdAt: _daysBeforeShot(design.daysAgo),
    extension: isFile ? _pdfExtension : '',
    details: design.details,
  );
}

final List<FolderUnit> _designUnits = [
  _unit((
    id: 'neuroscience',
    name: 'Neuroscience',
    type: UnitType.folder,
    daysAgo: 3,
    details: FolderDetails(itemCount: 6, editedAt: _daysBeforeShot(2)),
  )),
  _unit((
    id: 'deck',
    name: 'Action potentials — deck',
    type: UnitType.flashcardDeck,
    daysAgo: 4,
    details: const DeckDetails(cardCount: 30, dueCount: 12),
  )),
  _unit((
    id: 'test',
    name: 'Action potentials — test',
    type: UnitType.test,
    daysAgo: 5,
    details: const TestDetails(questionCount: 30, dueCount: 7),
  )),
  _unit((
    id: 'note',
    name: 'Action potentials — note',
    type: UnitType.note,
    daysAgo: 6,
    details: const NoteDetails(readingMinutes: 4),
  )),
  _unit((
    id: 'pdf',
    name: 'action-potentials.pdf',
    type: UnitType.file,
    daysAgo: 7,
    details: const FileDetails(sizeBytes: _designPdfBytes),
  )),
];

const DueSummary _designDue = DueSummary(
  flashcards: StudyCount(due: 12, done: 20),
  testItems: StudyCount(due: 7, done: 15),
  notes: StudyCount(due: 0, done: 6),
);

final FolderOverview filledHome = FolderOverview(
  listing: FolderListing(
    folderName: homeFolderName,
    units: _designUnits,
    ancestors: const [],
  ),
  due: _designDue,
  loadedAt: shotLoadedAt,
);

final FolderOverview emptySubfolder = FolderOverview(
  listing: const FolderListing(
    folderName: 'Neuroscience',
    units: [],
    ancestors: [FolderAncestor(id: _homeFolderUuid, name: homeFolderName)],
  ),
  due: const DueSummary(
    flashcards: StudyCount.nothing,
    testItems: StudyCount.nothing,
    notes: StudyCount.nothing,
  ),
  loadedAt: shotLoadedAt,
);
