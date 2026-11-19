import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leffic/shared/design/toast_host.dart';
import 'package:leffic/shared/import/generation_choices.dart';
import 'package:leffic/shared/import/generation_request.dart';
import 'package:leffic/shared/import/import_announcements.dart';
import 'package:leffic/shared/import/import_api.dart';
import 'package:leffic/shared/import/import_source.dart';
import 'package:leffic/shared/import/stored_source_files.dart';

import '../../support/backend_fakes.dart';
import '../../support/property.dart';
import 'import_fakes.dart';

const Map<String, Object?> _queuedTasks = {
  'note_task_id': 'note-task',
  'flashcard_deck_id': 'deck',
  'flashcard_task_ids': ['basic-task', 'feynman-task'],
  'test_id': 'test',
  'test_task_ids': ['test-task'],
};

typedef _Statuses = ({String basic, String feynman, String note, String test});

ReplyToRequest _settlingAs(String status) {
  var checks = 0;

  return (request) async {
    checks++;

    return jsonReply({'status': checks < 2 ? 'PENDING' : status});
  };
}

Map<String, ReplyToRequest> _generationReplies(_Statuses statuses) {
  return {
    '/generate-study-units': answerWith(_queuedTasks),
    '/flashcards-status/basic-task': _settlingAs(statuses.basic),
    '/flashcards-status/feynman-task': _settlingAs(statuses.feynman),
    '/note-task-status/note-task': _settlingAs(statuses.note),
    '/test-task-status/test-task': _settlingAs(statuses.test),
  };
}

_Statuses _generatedStatuses(Random random) {
  return (
    basic: oneOf(random, ['SUCCESS', 'FAILURE']),
    feynman: oneOf(random, ['SUCCESS', 'FAILURE']),
    note: oneOf(random, ['SUCCESS', 'FAILURE']),
    test: oneOf(random, ['SUCCESS', 'FAILURE']),
  );
}

Future<ToastHostState> _pumpHost(WidgetTester tester) async {
  final hostKey = GlobalKey<ToastHostState>();

  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      home: ToastHost(key: hostKey, child: const SizedBox.expand()),
    ),
  );

  return hostKey.currentState!;
}

GenerationRequest _requestFrom(ImportSource source) {
  return GenerationRequest(
    text: 'Reviewed text',
    folderId: 'target-folder',
    source: source,
    choices: GenerationChoices.starting,
  );
}

void main() {
  testWidgets('announceGeneration property reports each kind once settled', (
    tester,
  ) async {
    final examples = examplesOf(
      (random) => (generatedSource(random), _generatedStatuses(random)),
      runs: 6,
    );

    for (final (source, statuses) in examples) {
      final backend = FakeBackend(_generationReplies(statuses));
      final toasts = await _pumpHost(tester);
      final flashcardsTitle =
          statuses.basic == 'SUCCESS' && statuses.feynman == 'SUCCESS'
          ? 'Flashcards ready'
          : "Couldn't generate the flashcards";
      final noteTitle = statuses.note == 'SUCCESS'
          ? 'Note ready'
          : "Couldn't generate the note";
      final testTitle = statuses.test == 'SUCCESS'
          ? 'Test ready'
          : "Couldn't generate the test";

      final announcing = announceGeneration(
        toasts: toasts,
        api: ImportApi(backend.client()),
        request: _requestFrom(source),
        pollInterval: Duration.zero,
      );
      await tester.pump();

      expect(find.text('Generating from ${source.label}'), findsOneWidget);
      expect(find.text('About a minute. You can keep working.'), findsOne);

      await tester.pumpAndSettle();
      await announcing;

      final sent = sentBody(backend.sentTo('/generate-study-units').single);

      expect(sent['text'], 'Reviewed text');
      expect(sent['source_kind'], source.sourceKind);
      expect(find.text('Generating from ${source.label}'), findsNothing);
      expect(find.text(flashcardsTitle), findsOneWidget);
      expect(find.text(noteTitle), findsOneWidget);
      expect(find.text(testTitle), findsOneWidget);
    }
  });

  testWidgets('announceGeneration property reports a refused start', (
    tester,
  ) async {
    for (final source in examplesOf(generatedSource, runs: 4)) {
      final backend = FakeBackend({
        '/generate-study-units': failWith(400, 'There is no text!'),
      });
      final toasts = await _pumpHost(tester);

      final announcing = announceGeneration(
        toasts: toasts,
        api: ImportApi(backend.client()),
        request: _requestFrom(source),
        pollInterval: Duration.zero,
      );
      await tester.pumpAndSettle();
      await announcing;

      expect(find.text("Couldn't generate from ${source.label}"), findsOne);
      expect(find.text('There is no text!'), findsOneWidget);
      expect(find.text('Generating from ${source.label}'), findsNothing);
    }
  });

  testWidgets('announceUpload property uploads the file and says so', (
    tester,
  ) async {
    for (final (file, isRefused) in examplesOf(
      (random) => (
        generatedFile(random, oneOf(random, unpagedExtensions)),
        random.nextBool(),
      ),
      runs: 6,
    )) {
      final upload = Completer<http.Response>();
      final backend = FakeBackend({
        '/upload-files': (request) => upload.future,
      });
      final api = ImportApi(backend.client());
      final toasts = await _pumpHost(tester);
      final storedFile = {
        'file_metadata': [
          {'file_id': 'stored-file'},
        ],
      };
      final uploadReply = isRefused
          ? http.Response('{"detail":"Disk full"}', 500)
          : jsonReply(storedFile);

      final announcing = announceUpload(
        toasts: toasts,
        storedFiles: StoredSourceFiles(api: api, folderId: 'target-folder'),
        file: file,
      );
      await tester.pump();

      expect(find.text('Uploading ${file.name}'), findsOneWidget);

      upload.complete(uploadReply);
      await tester.pumpAndSettle();
      await announcing;

      expect(find.text('Uploading ${file.name}'), findsNothing);
      expect(
        find.text('${file.name} uploaded'),
        findsNWidgets(isRefused ? 0 : 1),
      );
      expect(
        find.text("Couldn't upload ${file.name}"),
        findsNWidgets(isRefused ? 1 : 0),
      );
      expect(backend.sentTo('/upload-files').single.body, contains(file.name));
    }
  });
}
