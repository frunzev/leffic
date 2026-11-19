import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/import/import_source.dart';

import '../../support/backend_fakes.dart';
import '../../support/property.dart';
import 'import_dialog_harness.dart';

void main() {
  testWidgets('showImportDialog property generates from the reviewed text', (
    tester,
  ) async {
    for (final (kind, typed, edited) in examplesOf(
      (random) => (
        oneOf(random, [ImportSourceKind.link, ImportSourceKind.file]),
        'https://${wordOf(random)}.org',
        'Edited ${wordOf(random)}',
      ),
      runs: 4,
    )) {
      final backend = FakeBackend(importReplies());
      final file = namedTextFile('notes.txt');
      final answers = await openImport(tester, backend, pickedFile: file);

      await chooseSource(tester, kind);

      if (kind == ImportSourceKind.file) {
        await tester.tap(find.text('Browse files'));
      } else {
        await tester.enterText(find.byType(TextField), typed);
      }

      await tester.pumpAndSettle();
      await continueToReview(tester);

      final label = kind == ImportSourceKind.file ? file.name : typed;

      expect(find.text('From $label'), findsOneWidget);
      expect(find.text('Extracted text'), findsOneWidget);
      expect(find.text(extractedText), findsOneWidget);

      await tester.enterText(find.byType(TextField), edited);
      await tester.pump();
      await tester.tap(find.widgetWithText(DesignButton, 'Generate'));
      await tester.pumpAndSettle();

      final generation = sentBody(
        backend.sentTo('/generate-study-units').single,
      );

      expect(answers, [true]);
      expect(generation['text'], edited);
      expect(generation['folder_id'], 'target-folder');
      expect(
        generation['source_kind'],
        kind == ImportSourceKind.file ? 'file' : 'link',
      );
      expect(find.text('Flashcards ready'), findsOneWidget);
      expect(find.text('Note ready'), findsOneWidget);
    }
  });

  testWidgets('showImportDialog property generates pasted text at once', (
    tester,
  ) async {
    for (final pasted in examplesOf(
      (random) => 'Pasted ${wordOf(random)}',
      runs: 3,
    )) {
      final backend = FakeBackend(importReplies());
      final answers = await openImport(tester, backend);

      await chooseSource(tester, ImportSourceKind.text);
      await tester.enterText(find.byType(TextField), pasted);
      await tester.pump();

      expect(find.text('Generate'), findsWidgets);

      await tester.tap(find.widgetWithText(DesignButton, 'Generate'));
      await tester.pumpAndSettle();

      final generation = sentBody(
        backend.sentTo('/generate-study-units').single,
      );

      expect(answers, [true]);
      expect(generation['text'], pasted);
      expect(generation['source_kind'], 'text');
      expect(backend.sentTo('/extract-text'), isEmpty);
    }
  });

  testWidgets('showImportDialog property reviews a topic before generating', (
    tester,
  ) async {
    for (final topic in examplesOf(wordOf, runs: 3)) {
      final backend = FakeBackend(importReplies());
      final answers = await openImport(tester, backend);

      await chooseSource(tester, ImportSourceKind.topic);
      await tester.enterText(find.byType(TextField), topic);
      await tester.pump();
      await continueToReview(tester);

      expect(find.text('From $topic'), findsOneWidget);

      await tester.tap(find.widgetWithText(DesignButton, 'Generate'));
      await tester.pumpAndSettle();

      final generation = sentBody(
        backend.sentTo('/generate-study-units').single,
      );

      expect(answers, [true]);
      expect(generation['text'], topic);
      expect(generation['source_kind'], 'topic');
      expect(generation['source_reference'], topic);
      expect(backend.sentTo('/extract-text'), isEmpty);
    }
  });

  testWidgets('showImportDialog property reads only the chosen pages', (
    tester,
  ) async {
    for (final (first, last) in examplesOf(
      (random) =>
          (integerBetween(random, 1, 9), integerBetween(random, 10, 40)),
      runs: 3,
    )) {
      final backend = FakeBackend(importReplies());
      final file = namedTextFile('chapter.pdf');

      await openImport(tester, backend, pickedFile: file);
      await tester.tap(find.text('Browse files'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '$first');
      await tester.enterText(find.byType(TextField).last, '$last');
      await tester.pump();
      await continueToReview(tester);

      final extraction = sentBody(backend.sentTo('/extract-text').single);
      final requested = (extraction['file_metadata']! as List<Object?>).single;

      expect((requested! as Map<String, Object?>)['pages'], {
        'first': first,
        'last': last,
      });
    }
  });

  testWidgets('showImportDialog property keeps the source when going back', (
    tester,
  ) async {
    final backend = FakeBackend(importReplies());
    final file = namedTextFile('notes.txt');

    await openImport(tester, backend, pickedFile: file);
    await tester.tap(find.text('Browse files'));
    await tester.pumpAndSettle();
    await continueToReview(tester);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text('notes.txt'), findsOneWidget);

    await continueToReview(tester);

    expect(find.text('From notes.txt'), findsOneWidget);
    expect(backend.sentTo('/upload-files').length, 1);
    expect(backend.sentTo('/extract-text').length, 2);
  });
}
