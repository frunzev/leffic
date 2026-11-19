import 'generation_tasks.dart';

class TaskProgress {
  const TaskProgress({required this.task, required this.outcome});

  final GenerationTask task;
  final TaskOutcome outcome;
}

class GeneratedKindOutcome {
  const GeneratedKindOutcome({required this.kind, required this.outcome});

  final GeneratedKind kind;
  final TaskOutcome outcome;
}

bool isEveryTaskSettled(List<TaskProgress> tasks) {
  for (final entry in tasks) {
    if (entry.outcome == TaskOutcome.pending) {
      return false;
    }
  }

  return true;
}

List<GeneratedKindOutcome> settledKindOutcomes(List<TaskProgress> tasks) {
  final outcomes = <GeneratedKindOutcome>[];

  for (final kind in GeneratedKind.values) {
    final tasksOfKind = [
      for (final entry in tasks)
        if (entry.task.kind == kind) entry,
    ];

    if (tasksOfKind.isEmpty || !isEveryTaskSettled(tasksOfKind)) {
      continue;
    }

    outcomes.add(
      GeneratedKindOutcome(kind: kind, outcome: _combinedOutcome(tasksOfKind)),
    );
  }

  return outcomes;
}

TaskOutcome _combinedOutcome(List<TaskProgress> settledTasks) {
  for (final entry in settledTasks) {
    if (entry.outcome == TaskOutcome.failed) {
      return TaskOutcome.failed;
    }
  }

  return TaskOutcome.succeeded;
}

Stream<GeneratedKindOutcome> announcedKindOutcomes(
  Stream<List<TaskProgress>> snapshots,
) async* {
  final announcedKinds = <GeneratedKind>{};

  await for (final snapshot in snapshots) {
    for (final kindOutcome in settledKindOutcomes(snapshot)) {
      final isNewlySettled = announcedKinds.add(kindOutcome.kind);

      if (isNewlySettled) {
        yield kindOutcome;
      }
    }
  }
}
