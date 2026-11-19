import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leffic/features/folders/due_models.dart';
import 'package:leffic/features/folders/folder_models.dart';
import 'package:leffic/features/folders/folders_api.dart';
import 'package:leffic/shared/api/api_error.dart';

import '../../support/backend_fakes.dart';
import '../../support/property.dart';
import 'folder_fakes.dart';

const Map<UnitType, (String, String)> _deleteEndpoints = {
  UnitType.folder: ('/delete-folder/', 'folder_id'),
  UnitType.flashcardDeck: ('/delete-deck/', 'deck_id'),
  UnitType.test: ('/delete-test/', 'test_id'),
  UnitType.note: ('/delete-note/', 'note_id'),
  UnitType.file: ('/delete-file/', 'file_id'),
};

FolderUnit _generatedUnit(Random random) {
  return FolderUnit.fromJson(generatedUnitJson(random, tokenOf(random)));
}

void main() {
  test('openFolder property asks for the folder and parses it', () async {
    for (final (folderId, listing) in examplesOf(
      (random) => (tokenOf(random), generatedListingJson(random)),
    )) {
      final backend = FakeBackend({'/access-folder/': answerWith(listing)});
      final api = FoldersApi(backend.client());

      final opened = await api.openFolder(folderId);
      final request = backend.received.single;

      expect(request.method, 'GET');
      expect(request.url.path, '/access-folder/');
      expect(request.url.queryParameters, {'folder_id': folderId});
      expect(opened.folderName, listing['parent_folder_name']);
      expect(opened.units.length, (listing['content']! as List).length);
    }
  });

  test('createFolder property posts the name under the parent', () async {
    for (final (parentId, name) in examplesOf(
      (random) => (tokenOf(random), wordOf(random)),
    )) {
      final backend = FakeBackend({'/create-folder': answerWith({})});

      await FoldersApi(backend.client())
          .createFolder(parentFolderId: parentId, name: name);
      final request = backend.received.single;

      expect(request.method, 'POST');
      expect(sentBody(request), {
        'parent_folder_id': parentId,
        'folder_name': name,
      });
    }
  });

  test('renameUnit property patches the id, type and new name', () async {
    for (final (unit, name) in examplesOf(
      (random) => (_generatedUnit(random), wordOf(random)),
    )) {
      final backend = FakeBackend({'/rename-unit': answerWith({})});

      await FoldersApi(backend.client()).renameUnit(unit: unit, name: name);
      final request = backend.received.single;

      expect(request.method, 'PATCH');
      expect(sentBody(request), {
        'unit_id': unit.id,
        'unit_type': unit.type.wireName,
        'name': name,
      });
    }
  });

  test('moveUnit property patches the id, type and destination', () async {
    for (final (unit, destination) in examplesOf(
      (random) => (_generatedUnit(random), tokenOf(random)),
    )) {
      final backend = FakeBackend({'/move-unit': answerWith({})});

      await FoldersApi(backend.client())
          .moveUnit(unit: unit, destinationFolderId: destination);
      final request = backend.received.single;

      expect(request.method, 'PATCH');
      expect(sentBody(request), {
        'unit_id': unit.id,
        'unit_type': unit.type.wireName,
        'folder_id': destination,
      });
    }
  });

  test('deleteUnit property uses the delete endpoint of the type', () async {
    for (final unit in examplesOf(_generatedUnit)) {
      final (path, queryKey) = _deleteEndpoints[unit.type]!;
      final backend = FakeBackend({path: answerWith({})});

      await FoldersApi(backend.client()).deleteUnit(unit);
      final request = backend.received.single;

      expect(request.method, 'DELETE');
      expect(request.url.path, path);
      expect(request.url.queryParameters, {queryKey: unit.id});
    }
  });

  test('flashcardsStats property reads due and done', () async {
    for (final (folderId, due, done) in examplesOf(
      (random) => (
        tokenOf(random),
        integerBetween(random, 0, 50),
        integerBetween(random, 0, 50),
      ),
    )) {
      final backend = FakeBackend({
        '/flashcards-stats': answerWith({'due': due, 'done': done}),
      });

      final count = await FoldersApi(backend.client())
          .flashcardsStats(folderId);

      expect(backend.received.single.url.queryParameters, {
        'folder_id': folderId,
      });
      expect((count.due, count.done), (due, done));
    }
  });

  test('testItemsStats property turns totals into due and done', () async {
    for (final (folderId, total, correct) in examplesOf(
      (random) => (
        tokenOf(random),
        integerBetween(random, 0, 50),
        integerBetween(random, 0, 50),
      ),
    )) {
      final backend = FakeBackend({
        '/test-items-stats': answerWith({'total': total, 'correct': correct}),
      });

      final count = await FoldersApi(backend.client()).testItemsStats(folderId);

      expect(backend.received.single.url.queryParameters, {
        'folder_id': folderId,
      });
      expect((count.due, count.done), (max(0, total - correct), correct));
    }
  });

  test('notesStats property reads due and read notes', () async {
    for (final (folderId, due, read) in examplesOf(
      (random) => (
        tokenOf(random),
        integerBetween(random, 0, 50),
        integerBetween(random, 0, 50),
      ),
    )) {
      final backend = FakeBackend({
        '/notes-stats': answerWith({'due': due, 'read': read}),
      });

      final count = await FoldersApi(backend.client()).notesStats(folderId);

      expect(backend.received.single.url.queryParameters, {
        'folder_id': folderId,
      });
      expect((count.due, count.done), (due, read));
    }
  });

  test(
    'FoldersApi property counts nothing when a stats route is 404',
    () async {
      for (final folderId in examplesOf(tokenOf, runs: 10)) {
        final api = FoldersApi(FakeBackend({}).client());

        final counts = [
          await api.flashcardsStats(folderId),
          await api.testItemsStats(folderId),
          await api.notesStats(folderId),
        ];

        expect(counts, everyElement(same(StudyCount.nothing)));
      }
    },
  );

  test('FoldersApi property raises other stats failures', () async {
    for (final status in examplesOf(
      (random) => oneOf(random, [400, 401, 422, 500, 503]),
      runs: 10,
    )) {
      final backend = FakeBackend({
        '/flashcards-stats': (request) async => http.Response('{}', status),
      });

      await expectLater(
        FoldersApi(backend.client()).flashcardsStats('folder'),
        throwsA(isA<ApiError>()),
      );
    }
  });
}
