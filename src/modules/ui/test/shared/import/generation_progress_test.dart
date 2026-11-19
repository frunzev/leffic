import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/import/generation_progress.dart';
import 'package:leffic/shared/import/generation_tasks.dart';

import '../../support/property.dart';

List<TaskProgress> _generatedTasks(Random random) {
  final count = random.nextInt(6);
  final tasks = <TaskProgress>[];

  for (var index = 0; index < count; index++) {
    final task = GenerationTask(
      kind: oneOf(random, GeneratedKind.values),
      id: 'task-$index',
    );

    tasks.add(
      TaskProgress(task: task, outcome: oneOf(random, TaskOutcome.values)),
    );
  }

  return tasks;
}

List<TaskProgress> _settledLater(Random random, List<TaskProgress> tasks) {
  return [
    for (final entry in tasks)
      TaskProgress(
        task: entry.task,
        outcome: entry.outcome == TaskOutcome.pending
            ? oneOf(random, TaskOutcome.values)
            : entry.outcome,
      ),
  ];
}

List<List<TaskProgress>> _generatedSnapshots(Random random) {
  final snapshots = [_generatedTasks(random)];
  final laterCount = random.nextInt(4);

  for (var index = 0; index < laterCount; index++) {
    snapshots.add(_settledLater(random, snapshots.last));
  }

  return snapshots;
}

void main() {
  test('isEveryTaskSettled property is false while any task is pending', () {
    forAll(_generatedTasks, (tasks) {
      var isAnyPending = false;

      for (final entry in tasks) {
        if (entry.outcome == TaskOutcome.pending) {
          isAnyPending = true;
        }
      }

      expect(isEveryTaskSettled(tasks), !isAnyPending);
    });
  });

  test('settledKindOutcomes property reports each fully settled kind', () {
    forAll(_generatedTasks, (tasks) {
      final outcomes = settledKindOutcomes(tasks);
      final reportedKinds = [for (final outcome in outcomes) outcome.kind];

      for (final kind in GeneratedKind.values) {
        final outcomesOfKind = [
          for (final entry in tasks)
            if (entry.task.kind == kind) entry.outcome,
        ];
        final isSettled =
            outcomesOfKind.isNotEmpty &&
            !outcomesOfKind.contains(TaskOutcome.pending);

        expect(reportedKinds.contains(kind), isSettled);

        if (isSettled) {
          final reported = outcomes.firstWhere((entry) => entry.kind == kind);
          final expected = outcomesOfKind.contains(TaskOutcome.failed)
              ? TaskOutcome.failed
              : TaskOutcome.succeeded;

          expect(reported.outcome, expected);
        }
      }

      expect(reportedKinds.toSet().length, reportedKinds.length);
    });
  });

  test('announcedKindOutcomes property names each settled kind once', () async {
    final examples = examplesOf(_generatedSnapshots, runs: 40);

    for (final snapshots in examples) {
      final announced = await announcedKindOutcomes(
        Stream.fromIterable(snapshots),
      ).toList();
      final announcedKinds = [for (final outcome in announced) outcome.kind];
      final finalOutcomes = settledKindOutcomes(snapshots.last);

      expect(announcedKinds.toSet().length, announcedKinds.length);
      expect(announcedKinds.toSet(), {
        for (final outcome in finalOutcomes) outcome.kind,
      });
    }
  });
}
