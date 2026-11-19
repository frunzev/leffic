import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/files/file_models.dart';

import '../../support/property.dart';
import 'file_fakes.dart';

void main() {
  test('bookmarkedPageFrom property reads the page or no bookmark', () {
    forAll(generatedBookmarkedPage, (page) {
      expect(bookmarkedPageFrom({'page': page}), page);
    });
  });

  test('bookmarkedPageFrom property refuses a page that is not whole', () {
    forAll(
      (random) => oneOf<Object>(random, [
        wordOf(random),
        integerBetween(random, 1, 500) + 0.5,
        [integerBetween(random, 1, 500)],
      ]),
      (page) {
        expect(() => bookmarkedPageFrom({'page': page}), throwsFormatException);
      },
    );
  });

  test('StoredFileDetails.fromJson property keeps every field', () {
    forAll(generatedFileDetailsJson, (json) {
      final details = StoredFileDetails.fromJson(json);

      expect(details.bookmarkedPage, json['page']);
      expect(details.pageCount, json['page_count']);
      expect(details.folderId, json['folder_id']);
      expect(details.folderName, json['folder_name']);
    });
  });

  test('StoredFileDetails.fromJson property fails fast on a missing field', () {
    forAll(
      (random) => (
        generatedFileDetailsJson(random),
        oneOf(random, ['page_count', 'folder_id', 'folder_name']),
      ),
      (example) {
        final (json, missingKey) = example;
        final broken = Map<String, Object?>.of(json)..remove(missingKey);

        expect(() => StoredFileDetails.fromJson(broken), throwsFormatException);
      },
    );
  });
}
