import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/notes/note_models.dart';
import 'package:leffic/shared/api/json_reading.dart';

import '../../support/property.dart';
import 'note_fakes.dart';

void main() {
  test('Note.fromJson property keeps the name, content and read state', () {
    forAll(generatedNoteJson, (json) {
      final note = Note.fromJson(json);

      expect(note.name, json['name']);
      expect(note.content, json['content']);
      expect(note.isRead, json['read']);
      expect(note.folderId, json['folder_id']);
      expect(note.source?.kind, json['source_kind']);
      expect(note.source?.reference, json['source_reference']);
    });
  });

  test('NoteSource.origin property names what the note came from', () {
    forAll((random) => (oneOf(random, sourceKinds), anyTextOf(random)), (
      example,
    ) {
      final (kind, reference) = example;
      final source = NoteSource(kind: kind, reference: reference);

      expect(source.origin, kind == 'text' ? 'your text' : reference);
    });
  });

  test('Note.fromJson property fails fast on a half-named source', () {
    forAll(
      (random) => (generatedNoteJson(random), oneOf(random, sourceKinds)),
      (example) {
        final (json, kind) = example;
        final broken = Map<String, Object?>.of(json)
          ..['source_kind'] = kind
          ..remove('source_reference');

        expect(() => Note.fromJson(broken), throwsFormatException);
      },
    );
  });

  test('NotesProgress.fromJson property counts every note once', () {
    forAll(generatedNotesStatsJson, (json) {
      final progress = NotesProgress.fromJson(json);

      expect(progress.read, json['read']);
      expect(progress.total, readWholeNumber(json, 'due') + progress.read);
      expect(
        () => NotesProgress.fromJson({'read': json['read']}),
        throwsFormatException,
      );
    });
  });

  test(
    'NotesProgress.afterOneMoreRead property reads one more of the same',
    () {
      forAll(generatedNotesStatsJson, (json) {
        final progress = NotesProgress.fromJson(json);
        final afterReading = progress.afterOneMoreRead();

        expect(afterReading.read, progress.read + 1);
        expect(afterReading.total, progress.total);
      });
    },
  );

  test('Note.fromJson property fails fast on a missing field', () {
    forAll(
      (random) => (
        generatedNoteJson(random),
        oneOf(random, ['name', 'content', 'read', 'folder_id']),
      ),
      (example) {
        final (json, missingKey) = example;
        final broken = Map<String, Object?>.of(json)..remove(missingKey);

        expect(() => Note.fromJson(broken), throwsFormatException);
      },
    );
  });

  test('Note.fromJson property refuses a read state that is not true '
      'or false', () {
    forAll(
      (random) => (
        generatedNoteJson(random),
        oneOf<Object>(random, [wordOf(random), integerBetween(random, 0, 1)]),
      ),
      (example) {
        final (json, readState) = example;
        final broken = Map<String, Object?>.of(json)..['read'] = readState;

        expect(() => Note.fromJson(broken), throwsFormatException);
      },
    );
  });
}
