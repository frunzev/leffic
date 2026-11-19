import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/files/file_opening.dart';
import 'package:leffic/features/files/files_api.dart';
import 'package:leffic/shared/api/api_error.dart';

import '../../support/backend_fakes.dart';
import '../../support/property.dart';
import 'file_fakes.dart';

void main() {
  test('openFile property writes the PDF and keeps the details', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp('files');
    addTearDown(() => temporaryDirectory.delete(recursive: true));

    for (final (file, pdfBytes, detailsJson) in examplesOf(
      (random) => (
        generatedFile(random),
        generatedPdfBytes(random),
        generatedFileDetailsJson(random),
      ),
    )) {
      final backend = FakeBackend({
        '/file': (request) async => pdfReply(pdfBytes),
        '/file-bookmark': answerWith(detailsJson),
      });

      final opened = await openFile(
        api: FilesApi(backend.client()),
        file: file,
        findTemporaryDirectory: () async => temporaryDirectory,
      );

      expect(opened.details.bookmarkedPage, detailsJson['page']);
      expect(opened.details.pageCount, detailsJson['page_count']);
      expect(opened.pdf.parent.path, temporaryDirectory.path);
      expect(opened.pdf.path, endsWith('.pdf'));
      expect(await opened.pdf.readAsBytes(), pdfBytes);
    }
  });

  test('openFile property makes a temporary directory that is gone', () async {
    final parentDirectory = await Directory.systemTemp.createTemp('files');
    addTearDown(() => parentDirectory.delete(recursive: true));

    for (final (file, pdfBytes, missingName) in examplesOf(
      (random) => (
        generatedFile(random),
        generatedPdfBytes(random),
        tokenOf(random, maximum: 12),
      ),
      runs: 8,
    )) {
      final missingDirectory = Directory(
        '${parentDirectory.path}/$missingName/purged',
      );
      final backend = FakeBackend({
        '/file': (request) async => pdfReply(pdfBytes),
        '/file-bookmark': answerWith({
          'page': null,
          'page_count': 3,
          'folder_id': 'folder',
          'folder_name': 'Biology',
        }),
      });

      if (missingDirectory.existsSync()) {
        missingDirectory.deleteSync(recursive: true);
      }

      final opened = await openFile(
        api: FilesApi(backend.client()),
        file: file,
        findTemporaryDirectory: () async => missingDirectory,
      );

      expect(opened.pdf.parent.path, missingDirectory.path);
      expect(await opened.pdf.readAsBytes(), pdfBytes);
    }
  });

  test('openFile property writes nothing when the backend fails', () async {
    for (final (file, failingPath) in examplesOf(
      (random) => (
        generatedFile(random),
        random.nextBool() ? '/file' : '/file-bookmark',
      ),
    )) {
      var directoryLookups = 0;
      final backend = FakeBackend({
        '/file': (request) async => pdfReply(Uint8List(8)),
        '/file-bookmark': answerWith({
          'page': null,
          'page_count': 3,
          'folder_id': 'folder',
          'folder_name': 'Biology',
        }),
      });
      backend.replies[failingPath] = failWith(404, 'File not found');

      await expectLater(
        openFile(
          api: FilesApi(backend.client()),
          file: file,
          findTemporaryDirectory: () async {
            directoryLookups++;

            return Directory.systemTemp;
          },
        ),
        throwsA(isA<ApiError>()),
      );
      expect(directoryLookups, 0);
    }
  });
}
