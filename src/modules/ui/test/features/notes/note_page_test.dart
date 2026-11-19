import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leffic/features/notes/note_page.dart';
import 'package:leffic/shared/design/spinner.dart';
import 'package:leffic/shared/navigation/routes.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import '../../support/property.dart';

void main() {
  testWidgets('NotePage property shows why its note failed with a retry', (
    tester,
  ) async {
    for (final (noteId, detail) in examplesOf(
      (random) => (tokenOf(random), 'Missing ${wordOf(random)}'),
      runs: 4,
    )) {
      final backend = FakeBackend({'/note': failWith(404, detail)});

      await tester.pumpWidget(
        hostedWithBackend(
          client: backend.client(),
          child: NotePage(
            key: UniqueKey(),
            arguments: UnitArguments(id: noteId),
          ),
          opened: [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(detail), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(backend.received.single.url.queryParameters, {'note_id': noteId});
    }
  });

  testWidgets('NotePage property shows a spinner while the note loads', (
    tester,
  ) async {
    final pendingReply = Completer<http.Response>();
    final backend = FakeBackend({'/note': (request) => pendingReply.future});

    await tester.pumpWidget(
      hostedWithBackend(
        client: backend.client(),
        child: const NotePage(arguments: UnitArguments(id: 'note')),
        opened: [],
      ),
    );
    await tester.pump();

    expect(find.byType(Spinner), findsOneWidget);
    expect(backend.received.single.url.path, '/note');
  });
}
