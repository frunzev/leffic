import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/api/api_client.dart';
import 'package:leffic/shared/import/import_draft.dart';
import 'package:leffic/shared/import/import_source.dart';

import '../../support/property.dart';
import 'import_fakes.dart';

ImportDraft _draft({
  required ImportSourceKind kind,
  UploadedFile? file,
  String link = '',
  String pastedText = '',
  String topic = '',
  String firstPageText = '',
  String lastPageText = '',
}) {
  return ImportDraft(
    kind: kind,
    file: file,
    link: link,
    pastedText: pastedText,
    topic: topic,
    firstPageText: firstPageText,
    lastPageText: lastPageText,
  );
}

ImportSource _readySource(DraftReading reading) {
  return switch (reading) {
    SourceReady(:final source) => source,
    SourceMissing(:final reason) => fail('Expected a source, got "$reason"'),
  };
}

void main() {
  test('ImportDraft.read property needs a chosen file', () {
    forAll((random) => '${random.nextInt(9)}', (pageText) {
      final reading = _draft(
        kind: ImportSourceKind.file,
        firstPageText: pageText,
      ).read();

      expect(reading, isA<SourceMissing>());
      expect((reading as SourceMissing).reason, 'Choose a file first.');
    });
  });

  test('ImportDraft.read property reads whole unpaged files', () {
    forAll(
      (random) => (
        generatedFile(random, oneOf(random, unpagedExtensions)),
        '${integerBetween(random, 1, 9)}',
      ),
      (example) {
        final (file, pageText) = example;
        final source = _readySource(
          _draft(
            kind: ImportSourceKind.file,
            file: file,
            firstPageText: pageText,
          ).read(),
        );

        expect(source, isA<FileImportSource>());
        expect((source as FileImportSource).file, file);
        expect(source.pages.isWholeDocument, isTrue);
      },
    );
  });

  test('ImportDraft.read property keeps valid page ranges of paged files', () {
    forAll(
      (random) => (
        generatedFile(random, oneOf(random, pagedExtensions)),
        generatedPages(random),
      ),
      (example) {
        final (file, pages) = example;
        final source = _readySource(
          _draft(
            kind: ImportSourceKind.file,
            file: file,
            firstPageText: ' ${pages.first ?? ''} ',
            lastPageText: '${pages.last ?? ''}',
          ).read(),
        );

        expect((source as FileImportSource).pages.toJson(), pages.toJson());
      },
    );
  });

  test('ImportDraft.read property refuses broken or backwards pages', () {
    forAll(
      (random) => (
        generatedFile(random, oneOf(random, pagedExtensions)),
        oneOf(random, [
          ('0', ''),
          ('-${integerBetween(random, 1, 9)}', ''),
          (wordOf(random), ''),
          ('', '2.5'),
          (
            '${integerBetween(random, 10, 20)}',
            '${integerBetween(random, 1, 9)}',
          ),
        ]),
      ),
      (example) {
        final (file, (first, last)) = example;
        final reading = _draft(
          kind: ImportSourceKind.file,
          file: file,
          firstPageText: first,
          lastPageText: last,
        ).read();

        expect(reading, isA<SourceMissing>());
      },
    );
  });

  test('ImportDraft.read property trims any link and needs one', () {
    forAll(
      (random) => oneOf(random, [
        '',
        '   ',
        'https://www.youtube.com/watch?v=${tokenOf(random)}',
        'https://${wordOf(random)}.org/${tokenOf(random)}',
      ]),
      (link) {
        final reading = _draft(
          kind: ImportSourceKind.link,
          link: ' $link ',
        ).read();

        if (link.trim().isEmpty) {
          expect((reading as SourceMissing).reason, 'Paste a link first.');
          return;
        }

        final source = _readySource(reading) as LinkImportSource;

        expect(source.address, link.trim());
      },
    );
  });

  test('ImportDraft.read property keeps pasted text exactly as typed', () {
    forAll((random) => oneOf(random, ['', ' \n ', ' ${wordOf(random)}\n']), (
      pastedText,
    ) {
      final reading = _draft(
        kind: ImportSourceKind.text,
        pastedText: pastedText,
      ).read();

      if (pastedText.trim().isEmpty) {
        expect((reading as SourceMissing).reason, 'Paste some text first.');
        return;
      }

      final source = _readySource(reading) as PastedTextImportSource;

      expect(source.text, pastedText);
    });
  });

  test('ImportDraft.read property trims topics and needs one', () {
    forAll((random) => oneOf(random, ['', '  ', wordOf(random)]), (topic) {
      final reading = _draft(
        kind: ImportSourceKind.topic,
        topic: '  $topic ',
      ).read();

      if (topic.trim().isEmpty) {
        expect((reading as SourceMissing).reason, 'Name a topic first.');
        return;
      }

      final source = _readySource(reading) as TopicImportSource;

      expect(source.topic, topic);
    });
  });
}
