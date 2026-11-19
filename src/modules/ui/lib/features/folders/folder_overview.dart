import 'due_models.dart';
import 'folder_models.dart';
import 'folders_api.dart';

class FolderOverview {
  const FolderOverview({
    required this.listing,
    required this.due,
    required this.loadedAt,
  });

  final FolderListing listing;
  final DueSummary due;
  final DateTime loadedAt;
}

Future<FolderOverview> loadFolderOverview({
  required FoldersApi api,
  required String folderId,
}) async {
  final listing = await api.openFolder(folderId);
  final flashcards = await api.flashcardsStats(folderId);
  final testItems = await api.testItemsStats(folderId);
  final notes = await api.notesStats(folderId);

  final due = DueSummary(
    flashcards: flashcards,
    testItems: testItems,
    notes: notes,
  );

  return FolderOverview(listing: listing, due: due, loadedAt: DateTime.now());
}
