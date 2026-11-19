import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/files/files_api.dart';
import 'package:leffic/shared/api/api_error.dart';

import '../../support/backend_fakes.dart';
import '../../support/property.dart';
import 'file_fakes.dart';

void main() {
  test('fetchPdf property asks for the file as PDF bytes', () async {
    for (final (file, pdfBytes) in examplesOf(
      (random) => (generatedFile(random), generatedPdfBytes(random)),
    )) {
      final backend = FakeBackend({
        '/file': (request) async => pdfReply(pdfBytes),
      });

      final fetched = await FilesApi(backend.client()).fetchPdf(file);
      final request = backend.received.single;

      expect(request.method, 'GET');
      expect(request.url.path, '/file');
      expect(request.url.queryParameters, {
        'file_id': file.id,
        'file_extension': file.extension,
      });
      expect(fetched, pdfBytes);
    }
  });

  test(
    'readFileDetails property reads the bookmark, pages and folder',
    () async {
      for (final (fileId, detailsJson) in examplesOf(
        (random) => (tokenOf(random), generatedFileDetailsJson(random)),
      )) {
        final backend = FakeBackend({
          '/file-bookmark': answerWith(detailsJson),
        });

        final details = await FilesApi(backend.client())
            .readFileDetails(fileId);
        final request = backend.received.single;

        expect(request.method, 'GET');
        expect(request.url.path, '/file-bookmark');
        expect(request.url.queryParameters, {'file_id': fileId});
        expect(details.bookmarkedPage, detailsJson['page']);
        expect(details.pageCount, detailsJson['page_count']);
        expect(details.folderId, detailsJson['folder_id']);
      }
    },
  );

  test('bookmarkPage property puts the page and returns it', () async {
    for (final (fileId, page) in examplesOf(
      (random) => (tokenOf(random), integerBetween(random, 1, 500)),
    )) {
      final backend = FakeBackend({
        '/file-bookmark': (request) async =>
            jsonReply({'page': sentBody(request)['page']}),
      });

      final bookmarkedPage = await FilesApi(backend.client())
          .bookmarkPage(fileId: fileId, page: page);
      final request = backend.received.single;

      expect(request.method, 'PUT');
      expect(request.url.path, '/file-bookmark');
      expect(sentBody(request), {'file_id': fileId, 'page': page});
      expect(bookmarkedPage, page);
    }
  });

  test('removeBookmark property deletes the bookmark of the file', () async {
    for (final fileId in examplesOf(tokenOf)) {
      final backend = FakeBackend({
        '/file-bookmark': answerWith({'page': null}),
      });

      await FilesApi(backend.client()).removeBookmark(fileId);
      final request = backend.received.single;

      expect(request.method, 'DELETE');
      expect(request.url.path, '/file-bookmark');
      expect(request.url.queryParameters, {'file_id': fileId});
    }
  });

  test('FilesApi property raises the failure the backend answers', () async {
    for (final (file, status) in examplesOf(
      (random) => (generatedFile(random), oneOf(random, [400, 404, 500])),
      runs: 10,
    )) {
      final backend = FakeBackend({
        '/file': failWith(status, 'Conversion failed'),
        '/file-bookmark': failWith(status, 'Conversion failed'),
      });
      final api = FilesApi(backend.client());
      final isFailure = throwsA(
        isA<ApiError>().having(
          (failure) => failure.statusCode,
          'statusCode',
          status,
        ),
      );

      await expectLater(api.fetchPdf(file), isFailure);
      await expectLater(api.readFileDetails(file.id), isFailure);
      await expectLater(api.bookmarkPage(fileId: file.id, page: 1), isFailure);
      await expectLater(api.removeBookmark(file.id), isFailure);
    }
  });
}
