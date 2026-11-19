import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leffic/shared/api/api_client.dart';
import 'package:leffic/shared/api/api_error.dart';
import 'package:leffic/shared/import/import_api.dart';
import 'package:leffic/shared/import/import_source.dart';
import 'package:leffic/shared/import/source_text_reader.dart';
import 'package:leffic/shared/import/stored_source_files.dart';

import '../../support/backend_fakes.dart';
import '../../support/property.dart';
import 'import_fakes.dart';

Map<String, ReplyToRequest> _readingReplies() {
  return {
    '/upload-files': answerWith({
      'file_metadata': [
        {'file_id': 'stored-file'},
      ],
    }),
    '/extract-text': answerWith({'text': 'Extracted text'}),
  };
}

List<UploadedFile> _generatedFiles(Random random) {
  final count = integerBetween(random, 1, 3);

  return [
    for (var index = 0; index < count; index++)
      generatedFile(random, oneOf(random, unpagedExtensions)),
  ];
}

SourceTextReader _readerFor(FakeBackend backend, String folderId) {
  final api = ImportApi(backend.client());

  return SourceTextReader(
    api: api,
    storedFiles: StoredSourceFiles(api: api, folderId: folderId),
  );
}

void main() {
  test(
    'StoredSourceFiles.store property uploads each file only once',
    () async {
      final examples = examplesOf(
        (random) => (
          tokenOf(random),
          _generatedFiles(random),
          integerBetween(random, 1, 3),
        ),
        runs: 10,
      );

      for (final (folderId, files, repeats) in examples) {
        final backend = FakeBackend(_readingReplies());
        final api = ImportApi(backend.client());
        final storedFiles = StoredSourceFiles(api: api, folderId: folderId);

        expect(storedFiles.isAnyStored, isFalse);

        for (var repeat = 0; repeat < repeats; repeat++) {
          for (final file in files) {
            expect(await storedFiles.store(file), 'stored-file');
          }
        }

        final uploads = backend.sentTo('/upload-files');

        expect(storedFiles.isAnyStored, isTrue);
        expect(uploads.length, files.length);
        expect(uploads.first.body, contains(folderId));
      }
    },
  );

  test(
    'SourceTextReader.read property reads each source its own way',
    () async {
      for (final source in examplesOf(generatedSource, runs: 20)) {
        final backend = FakeBackend(_readingReplies());
        final reader = _readerFor(backend, 'target-folder');

        final text = await reader.read(source);
        final uploads = backend.sentTo('/upload-files');
        final extractions = backend.sentTo('/extract-text');

        switch (source) {
          case FileImportSource():
            final expected = StoredFileExtraction(
              fileId: 'stored-file',
              pages: source.pages,
            );

            expect(uploads.single.body, contains('target-folder'));
            expect(sentBody(extractions.single), expected.toJson());
            expect(text, 'Extracted text');
          case StoredFileImportSource():
            final expected = StoredFileExtraction(
              fileId: source.fileId,
              pages: PageSelection.wholeDocument,
            );

            expect(uploads, isEmpty);
            expect(sentBody(extractions.single), expected.toJson());
            expect(text, 'Extracted text');
          case LinkImportSource():
            expect(uploads, isEmpty);
            expect(sentBody(extractions.single), {
              'link_metadata': source.address,
            });
            expect(text, 'Extracted text');
          case PastedTextImportSource():
            expect(backend.received, isEmpty);
            expect(text, source.text);
          case TopicImportSource():
            expect(backend.received, isEmpty);
            expect(text, source.topic);
        }
      }
    },
  );

  test(
    'SourceTextReader.read property passes on a refused extraction',
    () async {
      final statuses = examplesOf(
        (random) => oneOf(random, [400, 404, 500]),
        runs: 6,
      );

      for (final status in statuses) {
        final backend = FakeBackend({
          ..._readingReplies(),
          '/extract-text': (request) async => http.Response('{}', status),
        });
        final reader = _readerFor(backend, 'folder');

        await expectLater(
          reader.read(const LinkImportSource(address: 'https://leffic.app')),
          throwsA(isA<ApiError>()),
        );
      }
    },
  );
}
