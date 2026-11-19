import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leffic/features/folders/folder_loading.dart';
import 'package:leffic/features/folders/folder_models.dart';
import 'package:leffic/features/folders/folder_page.dart';
import 'package:leffic/features/folders/folder_view.dart';
import 'package:leffic/features/folders/unit_presentation.dart';
import 'package:leffic/features/folders/unit_routes.dart';
import 'package:leffic/shared/design/design_modal.dart';
import 'package:leffic/shared/navigation/routes.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import '../../support/property.dart';
import 'folder_fakes.dart';

class _GatedListing {
  _GatedListing(this.listing);

  final Map<String, Object?> listing;
  final Completer<void> gate = Completer<void>();

  Future<http.Response> reply(http.Request request) async {
    await gate.future;

    return jsonReply(listing);
  }
}

List<Map<String, Object?>> _listings(int runs) {
  final listings = <Map<String, Object?>>[];

  forAll(
    (random) {
      final units = generatedUnitJsons(random);

      return {
        'parent_folder_name': 'Folder ${wordOf(random)}',
        'content': [
          for (var index = 0; index < units.length; index++)
            {...units[index], 'name': 'Unit number $index'},
        ],
        'ancestors': generatedAncestorJsons(random),
      };
    },
    listings.add,
    runs: runs,
  );

  return listings;
}

Future<void> _pumpPage(
  WidgetTester tester,
  FakeBackend backend,
  List<RouteSettings> opened,
) async {
  await tester.pumpWidget(
    hostedWithBackend(
      client: backend.client(),
      opened: opened,
      child: FolderPage(
        key: UniqueKey(),
        arguments: const UnitArguments(id: 'shown-folder'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('FolderPage property titles the page with the folder name', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final listing in _listings(4)) {
      final backend = FakeBackend(folderReplies(listing));

      await _pumpPage(tester, backend, []);

      final crumbAndTitle = find.text(listing['parent_folder_name']! as String);

      expect(crumbAndTitle, findsNWidgets(2));
      expect(backend.sentTo('/access-folder/').single.url.queryParameters, {
        'folder_id': 'shown-folder',
      });
    }
  });

  testWidgets('FolderPage property opens every unit through its route', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final listing = _listings(1).single;
    final backend = FakeBackend(folderReplies(listing));
    final opened = <RouteSettings>[];

    await _pumpPage(tester, backend, opened);

    for (final json in listing['content']! as List<Map<String, Object?>>) {
      final unit = FolderUnit.fromJson(json);

      await tester.tap(find.text(unit.name));
      await tester.pumpAndSettle();

      expect(opened.last.name, routeForUnit(unit).name);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
    }

    expect(opened.length, (listing['content']! as List).length);
  });

  testWidgets('FolderPage property deletes a confirmed unit and reloads', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final listing = _listings(1).single;
    final unit = FolderUnit.fromJson(
      (listing['content']! as List<Map<String, Object?>>).first,
    );
    final backend = FakeBackend({
      ...folderReplies(listing),
      unit.type.deletePath: answerWith({}),
    });

    final deleteLabel = 'Delete ${unitNoun(unit.type)}';

    await _pumpPage(tester, backend, []);
    await tester.tap(find.bySemanticsLabel('More actions for ${unit.name}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(deleteLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(deleteLabel));
    await tester.pumpAndSettle();

    expect(backend.sentTo(unit.type.deletePath).single.method, 'DELETE');
    expect(backend.sentTo('/access-folder/').length, 2);
  });

  testWidgets('FolderPage property opens the import dialog', (tester) async {
    useDesktopSurface(tester);
    final backend = FakeBackend(folderReplies(_listings(1).single));

    await _pumpPage(tester, backend, []);
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    expect(find.byType(DesignModal), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    expect(find.byType(DesignModal), findsNothing);
    expect(backend.sentTo('/access-folder/').length, 1);
  });

  testWidgets('FolderPage property shows the skeleton until it loads', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final listing in _listings(3)) {
      final gated = _GatedListing(listing);
      final backend = FakeBackend({
        ...folderReplies(listing),
        '/access-folder/': gated.reply,
        '/create-folder': answerWith({}),
      });

      await tester.pumpWidget(
        hostedWithBackend(
          client: backend.client(),
          opened: [],
          child: FolderPage(
            key: UniqueKey(),
            arguments: const UnitArguments(id: homeFolderId),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FolderLoading), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FolderLoading),
          matching: find.text(homeFolderName),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('New folder'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Created');
      await tester.pump();
      await tester.tap(find.text('Create'));
      await tester.pump();

      gated.gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(FolderLoading), findsNothing);
      expect(find.byType(FolderView), findsOneWidget);
      expect(backend.sentTo('/create-folder'), hasLength(1));
      expect(backend.sentTo('/access-folder/'), hasLength(2));
    }
  });

  testWidgets('FolderPage property shows a failure it can retry', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final backend = FakeBackend({
      '/access-folder/': (request) async =>
          http.Response('{"detail":"Folder does not exist!"}', 404),
    });

    await _pumpPage(tester, backend, []);

    expect(find.text('Folder does not exist!'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
