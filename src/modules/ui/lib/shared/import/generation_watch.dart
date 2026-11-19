import 'generation_progress.dart';
import 'generation_tasks.dart';
import 'import_api.dart';

const Duration generationPollInterval = Duration(seconds: 2);

Stream<List<TaskProgress>> watchGeneration({
  required ImportApi api,
  required List<GenerationTask> tasks,
  required Duration pollInterval,
}) async* {
  var snapshot = [
    for (final task in tasks)
      TaskProgress(task: task, outcome: TaskOutcome.pending),
  ];

  yield snapshot;

  while (!isEveryTaskSettled(snapshot)) {
    await Future<void>.delayed(pollInterval);

    snapshot = await _checkedTasks(api, snapshot);

    yield snapshot;
  }
}

Future<List<TaskProgress>> _checkedTasks(
  ImportApi api,
  List<TaskProgress> tasks,
) async {
  final checked = <TaskProgress>[];

  for (final entry in tasks) {
    if (entry.outcome != TaskOutcome.pending) {
      checked.add(entry);
      continue;
    }

    final outcome = await api.taskOutcome(entry.task);

    checked.add(TaskProgress(task: entry.task, outcome: outcome));
  }

  return checked;
}
