import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leffic/features/files/file_page.dart';
import 'package:leffic/shared/design/spinner.dart';
import 'package:leffic/shared/navigation/routes.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import '../../support/property.dart';
import 'file_fakes.dart';

void main() {
  testWidgets('FilePage property explains why its file failed to open', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final (file, detail) in examplesOf(
      (random) => (generatedFile(random), 'Missing ${wordOf(random)}'),
      runs: 4,
    )) {
      final backend = FakeBackend({
        '/file': failWith(404, detail),
        '/file-bookmark': failWith(404, detail),
      });

      await tester.pumpWidget(
        hostedWithBackend(
          client: backend.client(),
          child: FilePage(key: UniqueKey(), arguments: file),
          opened: [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Couldn't open ${file.name}"), findsOneWidget);
      expect(find.text(detail), findsOneWidget);
      expect(backend.received.first.url.queryParameters['file_id'], file.id);
    }
  });

  testWidgets('FilePage property shows a spinner while the file opens', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final pendingReply = Completer<http.Response>();
    final backend = FakeBackend({
      '/file': (request) => pendingReply.future,
      '/file-bookmark': (request) => pendingReply.future,
    });
    const file = FileArguments(
      id: 'file',
      name: 'Lecture.pptx',
      extension: 'pptx',
    );

    await tester.pumpWidget(
      hostedWithBackend(
        client: backend.client(),
        child: const FilePage(arguments: file),
        opened: [],
      ),
    );
    await tester.pump();

    expect(find.text('Opening Lecture.pptx…'), findsOneWidget);
    expect(find.byType(Spinner), findsOneWidget);
  });
}
