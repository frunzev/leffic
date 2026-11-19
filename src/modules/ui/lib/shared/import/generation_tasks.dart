import '../api/json_reading.dart';

enum GeneratedKind {
  flashcards(label: 'Flashcards', statusPath: '/flashcards-status/'),
  note(label: 'Note', statusPath: '/note-task-status/'),
  test(label: 'Test', statusPath: '/test-task-status/');

  const GeneratedKind({required this.label, required this.statusPath});

  final String label;
  final String statusPath;
}

class GenerationTask {
  const GenerationTask({required this.kind, required this.id});

  final GeneratedKind kind;
  final String id;
}

enum TaskOutcome {
  pending,
  succeeded,
  failed;

  static TaskOutcome fromStatus(String status) {
    return switch (status) {
      'SUCCESS' => succeeded,
      'FAILURE' || 'REVOKED' => failed,
      _ => pending,
    };
  }
}

List<GenerationTask> generationTasksFromJson(JsonObject json) {
  final tasks = <GenerationTask>[];

  for (final id in _queuedIds(json, 'flashcard_task_ids')) {
    tasks.add(GenerationTask(kind: GeneratedKind.flashcards, id: id));
  }

  if (json.containsKey('note_task_id')) {
    final noteTaskId = readText(json, 'note_task_id');

    tasks.add(GenerationTask(kind: GeneratedKind.note, id: noteTaskId));
  }

  for (final id in _queuedIds(json, 'test_task_ids')) {
    tasks.add(GenerationTask(kind: GeneratedKind.test, id: id));
  }

  return tasks;
}

List<String> _queuedIds(JsonObject json, String key) {
  if (!json.containsKey(key)) {
    return const [];
  }

  return readTexts(json, key);
}
