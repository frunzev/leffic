import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/folders/due_models.dart';
import 'package:leffic/features/folders/due_section.dart';
import 'package:leffic/features/folders/folder_header.dart';
import 'package:leffic/features/folders/folder_models.dart';
import 'package:leffic/features/folders/folder_overview.dart';
import 'package:leffic/features/folders/folder_view.dart';
import 'package:leffic/features/folders/folders_api.dart';
import 'package:leffic/features/folders/unit_list.dart';
import 'package:leffic/features/folders/unit_presentation.dart';
import 'package:leffic/features/folders/unit_row.dart';
import 'package:leffic/shared/design/button_look.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_modal.dart';
import 'package:leffic/shared/design/state_block.dart';
import 'package:leffic/shared/import/import_api.dart';
import 'package:leffic/shared/navigation/routes.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';
import 'folder_fakes.dart';

const DueSummary _somethingDue = DueSummary(
  flashcards: StudyCount(due: 2, done: 1),
  testItems: StudyCount(due: 3, done: 0),
  notes: StudyCount.nothing,
);
const String _reviewLabel = 'Review 5 items';
final DateTime _loadedAt = DateTime(2026, 11, 18, 12);

FolderOverview _overviewOf(
  List<Map<String, Object?>> unitJsons, {
  List<Map<String, Object?>> ancestors = const [],
}) {
  final named = [
    for (var index = 0; index < unitJsons.length; index++)
      {...unitJsons[index], 'name': 'Unit number $index'},
  ];
  final listing = FolderListing.fromJson({
    'parent_folder_name': 'Biology',
    'content': named,
    'ancestors': ancestors,
  });

  return FolderOverview(
    listing: listing,
    due: _somethingDue,
    loadedAt: _loadedAt,
  );
}

List<FolderOverview> _filledOverviews(int runs) {
  return examplesOf(
    (random) => _overviewOf(
      generatedUnitJsons(random),
      ancestors: generatedAncestorJsons(random),
    ),
    runs: runs,
  );
}

Widget _viewHost(
  FolderOverview overview,
  List<RouteSettings> opened,
  VoidCallback onChanged,
) {
  final client = FakeBackend({}).client();

  return hostedWithBackend(
    client: client,
    opened: opened,
    child: Scaffold(
      body: FolderView(
        folderId: 'biology-folder',
        overview: overview,
        foldersApi: FoldersApi(client),
        importApi: ImportApi(client),
        onChanged: onChanged,
      ),
    ),
  );
}

DesignButton _buttonLabelled(WidgetTester tester, String label) {
  return tester.widget<DesignButton>(
    find.ancestor(of: find.text(label), matching: find.byType(DesignButton)),
  );
}

void main() {
  testWidgets('FolderView property lists the units newest first', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final overview in _filledOverviews(5)) {
      await tester.pumpWidget(_viewHost(overview, [], () {}));

      final units = overview.listing.units;
      final rows = tester.widgetList<UnitRow>(find.byType(UnitRow)).toList();

      expect(
        [for (final row in rows) row.unit.id],
        [for (final unit in units) unit.id],
      );

      for (var index = 0; index < units.length; index++) {
        final meta = unitMetaLine(unit: units[index], now: _loadedAt);
        final corners = unitRowCorners(index: index, count: units.length);

        expect(rows[index].meta, meta);
        expect(rows[index].dueCount, unitDueCount(units[index]));
        expect(rows[index].corners, corners);
        expect(find.text(meta), findsWidgets);
      }

      for (var index = 1; index < units.length; index++) {
        final above = tester.getTopLeft(find.text(units[index - 1].name));
        final below = tester.getTopLeft(find.text(units[index].name));

        expect(above.dy, lessThan(below.dy));
      }
    }
  });

  testWidgets('FolderView property crumbs the folder under its ancestors', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final overview in _filledOverviews(4)) {
      await tester.pumpWidget(_viewHost(overview, [], () {}));

      final header = tester.widget<FolderHeader>(find.byType(FolderHeader));

      expect(header.ancestors, overview.listing.ancestors);
      expect(header.folderName, overview.listing.folderName);
    }
  });

  testWidgets('FolderView property heads the list with its count', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final overview in _filledOverviews(4)) {
      await tester.pumpWidget(_viewHost(overview, [], () {}));

      final count = itemCountLabel(overview.listing.units.length);
      final countLabel = tester.getRect(find.text(count));
      final note = tester.getRect(find.text('Newest first'));
      final list = tester.getRect(find.byType(UnitList));

      expect(renderedStyleOf(tester, 'Newest first').fontSize, 14);
      expect(note.right, list.right);
      expect(countLabel.left, list.left);
      expect(list.top - countLabel.bottom, closeTo(12, 0.01));
    }
  });

  testWidgets('FolderView property shows the empty state with Import', (
    tester,
  ) async {
    useDesktopSurface(tester);

    await tester.pumpWidget(_viewHost(_overviewOf([]), [], () {}));

    final import = _buttonLabelled(tester, 'Import');

    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.byType(DueSection), findsNothing);
    expect(find.text('Newest first'), findsNothing);
    expect(_buttonLabelled(tester, 'New folder').size, ButtonSize.small);
    expect(import.variant, ButtonVariant.primary);
    expect(import.size, ButtonSize.large);
    expect(
      find.descendant(
        of: find.byType(StateBlock),
        matching: find.text('Import'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    expect(find.byType(DesignModal), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    expect(find.byType(DesignModal), findsNothing);
  });

  testWidgets('FolderView property puts Import beside New folder when full', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final overview in _filledOverviews(3)) {
      await tester.pumpWidget(_viewHost(overview, [], () {}));

      final import = _buttonLabelled(tester, 'Import');

      expect(find.byType(StateBlock), findsNothing);
      expect(find.byType(DueSection), findsOneWidget);
      expect(import.variant, ButtonVariant.standard);
      expect(import.size, ButtonSize.small);

      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();

      expect(find.byType(DesignModal), findsOneWidget);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('FolderView property reviews this folder and then reloads', (
    tester,
  ) async {
    useDesktopSurface(tester);
    const reviews = {
      'Flashcards': Routes.folderReview,
      'Test': Routes.folderTest,
    };
    final overview = _filledOverviews(1).single;

    for (final MapEntry(key: label, value: route) in reviews.entries) {
      final opened = <RouteSettings>[];
      var changes = 0;

      await tester.pumpWidget(_viewHost(overview, opened, () => changes++));
      await tester.tap(find.text(_reviewLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      final arguments = opened.single.arguments! as UnitArguments;

      expect(opened.single.name, route);
      expect(arguments.id, 'biology-folder');
      expect(arguments.name, 'Biology');

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      expect(changes, 1);
    }
  });
}
