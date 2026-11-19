import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/import/import_source.dart';

import '../../support/property.dart';
import 'import_fakes.dart';

void main() {
  test('ImportSourceKind property lists the four design sources in order', () {
    forAll((random) => random.nextInt(ImportSourceKind.values.length), (index) {
      const labels = ['File', 'Link', 'Text', 'Topic'];

      expect(ImportSourceKind.values[index].label, labels[index]);
      expect(ImportSourceKind.values.length, labels.length);
    });
  });

  test('isPagedFileName property spots paged documents in any case', () {
    forAll(
      (random) => (
        wordOf(random),
        oneOf(random, [...pagedExtensions, ...unpagedExtensions]),
        random.nextBool(),
      ),
      (example) {
        final (stem, extension, isShouted) = example;
        final written = isShouted ? extension.toUpperCase() : extension;

        expect(
          isPagedFileName('$stem.$written'),
          pagedExtensions.contains(extension),
        );
      },
    );
  });

  test('PageSelection.toJson property names only the chosen pages', () {
    forAll(generatedPages, (pages) {
      final json = pages.toJson();

      expect(json.containsKey('first'), pages.first != null);
      expect(json.containsKey('last'), pages.last != null);
      expect(json['first'], pages.first);
      expect(json['last'], pages.last);
      expect(pages.isWholeDocument, json.isEmpty);
    });
  });

  test('ImportSource property names its kind, reference and label', () {
    forAll(generatedSource, (source) {
      final (expectedKind, expectedReference, expectedLabel) = switch (source) {
        FileImportSource() => ('file', source.file.name, source.file.name),
        StoredFileImportSource() => ('file', source.fileName, source.fileName),
        LinkImportSource() => ('link', source.address, source.address),
        PastedTextImportSource() => ('text', '', 'your text'),
        TopicImportSource() => ('topic', source.topic, source.topic),
      };

      expect(source.sourceKind, expectedKind);
      expect(source.reference, expectedReference);
      expect(source.label, expectedLabel);
    });
  });

  test('StoredFileExtraction.toJson property asks for one stored file', () {
    forAll((random) => (tokenOf(random), generatedPages(random)), (example) {
      final (fileId, pages) = example;
      final json = StoredFileExtraction(fileId: fileId, pages: pages).toJson();
      final files = json['file_metadata']! as List<Object?>;
      final requested = files.single! as Map<String, Object?>;

      expect(json.keys, ['file_metadata']);
      expect(requested['file_id'], fileId);
      expect(requested.containsKey('pages'), !pages.isWholeDocument);

      if (!pages.isWholeDocument) {
        expect(requested['pages'], pages.toJson());
      }
    });
  });

  test('LinkExtraction.toJson property asks for the link only', () {
    forAll((random) => 'https://${tokenOf(random)}.com', (address) {
      expect(LinkExtraction(address: address).toJson(), {
        'link_metadata': address,
      });
    });
  });
}
