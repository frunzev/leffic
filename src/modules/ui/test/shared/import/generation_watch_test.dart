import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/import/generation_progress.dart';
import 'package:leffic/shared/import/generation_tasks.dart';
import 'package:leffic/shared/import/generation_watch.dart';
import 'package:leffic/shared/import/import_api.dart';

import '../../support/backend_fakes.dart';
import '../../support/property.dart';

typedef _StatusScript = Map<GenerationTask, List<String>>;

ReplyToRequest _scriptedStatuses(List<String> statuses) {
  final remaining = List<String>.of(statuses);

  return (request) async {
    final status = remaining.length > 1 ? remaining.removeAt(0) : remaining[0];

    return jsonReply({'status': status});
  };
}

Map<String, ReplyToRequest> _statusReplies(_StatusScript script) {
  return {
    for (final MapEntry(key: task, value: statuses) in script.entries)
      '${task.kind.statusPath}${task.id}': _scriptedStatuses(statuses),
  };
}

_StatusScript _generatedScript(Random random) {
  final script = <GenerationTask, List<String>>{};
  final count = integerBetween(random, 1, 4);

  for (var index = 0; index < count; index++) {
    final task = GenerationTask(
      kind: oneOf(random, GeneratedKind.values),
      id: 'task-$index',
    );
    final waits = random.nextInt(4);

    script[task] = [
      for (var wait = 0; wait < waits; wait++)
        oneOf(random, ['PENDING', 'STARTED']),
      oneOf(random, ['SUCCESS', 'FAILURE']),
    ];
  }

  return script;
}

void main() {
  test('watchGeneration property polls until every task settles', () async {
    final scripts = <_StatusScript>[];
    forAll(_generatedScript, scripts.add, runs: 30);

    for (final script in scripts) {
      final backend = FakeBackend(_statusReplies(script));

      final snapshots = await watchGeneration(
        api: ImportApi(backend.client()),
        tasks: script.keys.toList(),
        pollInterval: Duration.zero,
      ).toList();
      final finalOutcomes = {
        for (final entry in snapshots.last) entry.task: entry.outcome,
      };
      final settledSnapshots = snapshots.where(isEveryTaskSettled);

      expect(isEveryTaskSettled(snapshots.first), isFalse);
      expect(settledSnapshots.length, 1);

      for (final MapEntry(key: task, value: statuses) in script.entries) {
        final statusPath = '${task.kind.statusPath}${task.id}';

        expect(finalOutcomes[task], TaskOutcome.fromStatus(statuses.last));
        expect(backend.sentTo(statusPath).length, statuses.length);
      }
    }
  });

  test(
    'watchGeneration property ends at once when nothing was queued',
    () async {
      final pollIntervals = examplesOf(
        (random) => Duration(milliseconds: random.nextInt(3)),
        runs: 3,
      );

      for (final pollInterval in pollIntervals) {
        final backend = FakeBackend({});

        final snapshots = await watchGeneration(
          api: ImportApi(backend.client()),
          tasks: const [],
          pollInterval: pollInterval,
        ).toList();

        expect(snapshots, [isEmpty]);
        expect(backend.received, isEmpty);
      }
    },
  );
}
