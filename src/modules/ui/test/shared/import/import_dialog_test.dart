import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leffic/shared/import/import_source.dart';

import '../../support/backend_fakes.dart';
import '../../support/property.dart';
import 'import_dialog_harness.dart';

void main() {
  testWidgets('showImportDialog property names the folder it saves into', (
    tester,
  ) async {
    await openImport(tester, FakeBackend(importReplies()));

    expect(find.text('Import'), findsOneWidget);
    expect(find.text('Saved into Biology.'), findsOneWidget);

    for (final kind in ImportSourceKind.values) {
      expect(find.text(kind.label), findsOneWidget);
    }
  });

  testWidgets('showImportDialog property names what each source still needs', (
    tester,
  ) async {
    const hints = {
      ImportSourceKind.file: 'Choose a file first.',
      ImportSourceKind.link: 'Paste a link first.',
      ImportSourceKind.text: 'Paste some text first.',
      ImportSourceKind.topic: 'Name a topic first.',
    };

    await openImport(tester, FakeBackend(importReplies()));

    for (final MapEntry(key: kind, value: hint) in hints.entries) {
      final primaryLabel = kind == ImportSourceKind.text
          ? 'Generate'
          : 'Continue';

      await chooseSource(tester, kind);

      expect(find.text(hint), findsOneWidget);
      expect(isButtonEnabled(tester, primaryLabel), isFalse);
    }
  });

  testWidgets('showImportDialog property uploads a file on its own', (
    tester,
  ) async {
    final backend = FakeBackend(importReplies());
    final file = namedTextFile('notes.txt');
    final answers = await openImport(tester, backend, pickedFile: file);

    expect(find.text('Upload only'), findsNothing);

    await tester.tap(find.text('Browse files'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload only'));
    await tester.pumpAndSettle();

    expect(answers, [true]);
    expect(find.text('notes.txt uploaded'), findsOneWidget);
    expect(backend.sentTo('/upload-files').single.body, contains('notes.txt'));
    expect(backend.sentTo('/generate-study-units'), isEmpty);
  });

  testWidgets('showImportDialog property shows the source being read', (
    tester,
  ) async {
    final extraction = Completer<http.Response>();
    final backend = FakeBackend({
      ...importReplies(),
      '/extract-text': (request) => extraction.future,
    });
    final file = namedTextFile('notes.txt');
    final answers = await openImport(tester, backend, pickedFile: file);

    await tester.tap(find.text('Browse files'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Reading notes.txt…'), findsOneWidget);
    expect(
      find.text('You will see the text before anything is generated.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump();

    expect(answers, [true]);
    expect(find.text('Reading notes.txt…'), findsNothing);
  });

  testWidgets(
    'showImportDialog property returns to the source when reading fails',
    (tester) async {
      for (final address in examplesOf(
        (random) => 'https://${wordOf(random)}.org',
        runs: 3,
      )) {
        final backend = FakeBackend({
          ...importReplies(),
          '/extract-text': failWith(400, 'Could not extract text!'),
        });
        final answers = await openImport(tester, backend);

        await chooseSource(tester, ImportSourceKind.link);
        await tester.enterText(find.byType(TextField), address);
        await tester.pump();
        await continueToReview(tester);

        expect(find.text("Couldn't read $address"), findsOneWidget);
        expect(find.text('Could not extract text!'), findsOneWidget);
        expect(find.text('Page address'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(answers, [false]);
        expect(backend.sentTo('/generate-study-units'), isEmpty);
      }
    },
  );

  testWidgets('showImportDialog property answers false when cancelled', (
    tester,
  ) async {
    final backend = FakeBackend(importReplies());
    final answers = await openImport(tester, backend);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(answers, [false]);
    expect(backend.received, isEmpty);
  });
}
