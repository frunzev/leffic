import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/folders/folder_overview.dart';
import 'package:leffic/features/folders/folders_api.dart';

import '../../support/backend_fakes.dart';
import '../../support/property.dart';
import 'folder_fakes.dart';

void main() {
  test(
    'loadFolderOverview property joins the listing, stats and load time',
    () async {
      final examples = <(String, Map<String, Object?>, int)>[];
      forAll(
        (random) => (
          tokenOf(random),
          generatedListingJson(random),
          integerBetween(random, 0, 40),
        ),
        examples.add,
        runs: 20,
      );

      for (final (folderId, listing, count) in examples) {
        final backend = FakeBackend({
          '/access-folder/': answerWith(listing),
          '/flashcards-stats': answerWith({'due': count, 'done': 1}),
          '/test-items-stats': answerWith({'total': count, 'correct': 0}),
          '/notes-stats': answerWith({'due': count, 'read': 2}),
        });

        final before = DateTime.now();
        final overview = await loadFolderOverview(
          api: FoldersApi(backend.client()),
          folderId: folderId,
        );
        final after = DateTime.now();

        expect(overview.listing.folderName, listing['parent_folder_name']);
        expect(overview.due.dueCount, count * 3);
        expect(overview.due.doneCount, 3);
        expect(overview.loadedAt.isBefore(before), isFalse);
        expect(overview.loadedAt.isAfter(after), isFalse);

        for (final request in backend.received) {
          expect(request.url.queryParameters['folder_id'], folderId);
        }
      }
    },
  );
}
