import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/import/generation_request.dart';
import 'package:leffic/shared/import/generation_tasks.dart';

import '../../support/property.dart';
import 'import_fakes.dart';

const List<String> _waitingStatuses = ['PENDING', 'STARTED', 'RETRY'];

List<String> _generatedIds(int count) {
  return [for (var index = 0; index < count; index++) 'task-$index'];
}

void main() {
  test('generationTasksFromJson property lists every queued task', () {
    forAll(
      (random) => (
        oneOf(random, [null, _generatedIds(random.nextInt(4))]),
        oneOf(random, [null, 'note-task']),
        oneOf(random, [null, _generatedIds(random.nextInt(4))]),
      ),
      (example) {
        final (flashcardIds, noteId, testIds) = example;
        final tasks = generationTasksFromJson({
          'flashcard_task_ids': ?flashcardIds,
          'note_task_id': ?noteId,
          'test_task_ids': ?testIds,
        });
        final expected = [
          for (final id in flashcardIds ?? <String>[])
            (GeneratedKind.flashcards, id),
          if (noteId != null) (GeneratedKind.note, noteId),
          for (final id in testIds ?? <String>[]) (GeneratedKind.test, id),
        ];

        expect([for (final task in tasks) (task.kind, task.id)], expected);
      },
    );
  });

  test('generationTasksFromJson property fails fast on a bad id list', () {
    forAll((random) => oneOf(random, ['flashcard_task_ids', 'test_task_ids']), (
      key,
    ) {
      expect(
        () => generationTasksFromJson({key: 'not a list'}),
        throwsFormatException,
      );
    });
  });

  test('TaskOutcome.fromStatus property waits until a task is settled', () {
    forAll(
      (random) => oneOf(random, [
        'SUCCESS',
        'FAILURE',
        'REVOKED',
        ..._waitingStatuses,
        wordOf(random),
      ]),
      (status) {
        final expected = switch (status) {
          'SUCCESS' => TaskOutcome.succeeded,
          'FAILURE' || 'REVOKED' => TaskOutcome.failed,
          _ => TaskOutcome.pending,
        };

        expect(TaskOutcome.fromStatus(status), expected);
      },
    );
  });

  test('GenerationRequest.toJson property carries text, folder and source', () {
    forAll(
      (random) => GenerationRequest(
        text: anyTextOf(random),
        folderId: tokenOf(random),
        source: generatedSource(random),
        choices: generatedChoices(random),
      ),
      (request) {
        final json = request.toJson();

        expect(json['text'], request.text);
        expect(json['folder_id'], request.folderId);
        expect(json['source_kind'], request.source.sourceKind);
        expect(json['source_reference'], request.source.reference);

        for (final MapEntry(:key, :value) in request.choices.toJson().entries) {
          expect(json[key], value);
        }
      },
    );
  });
}
