import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:leffic/features/folders/folder_models.dart';
import 'package:leffic/features/folders/folders_api.dart';
import 'package:leffic/features/folders/unit_actions.dart';
import 'package:leffic/features/folders/unit_presentation.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import '../../support/property.dart';
import 'folder_fakes.dart';

const List<MoveDestination> _destinations = [
  MoveDestination(id: 'home', name: 'Home'),
  MoveDestination(id: 'target-folder', name: 'Target'),
];

Widget _actionsHost(UnitActions actions, FolderUnit unit) {
  return hostedPlainly(
    Builder(
      builder: (context) => Column(
        children: [
          TextButton(
            onPressed: () => actions.createFolder(context),
            child: const Text('run create'),
          ),
          TextButton(
            onPressed: () => actions.rename(context, unit),
            child: const Text('run rename'),
          ),
          TextButton(
            onPressed: () => actions.move(context, unit, _destinations),
            child: const Text('run move'),
          ),
          TextButton(
            onPressed: () => actions.delete(context, unit),
            child: const Text('run delete'),
          ),
        ],
      ),
    ),
  );
}

List<FolderUnit> _generatedUnits(int runs) {
  final units = <FolderUnit>[];

  forAll(
    (random) => FolderUnit.fromJson(generatedUnitJson(random, tokenOf(random))),
    units.add,
    runs: runs,
  );

  return units;
}

Future<void> _run(WidgetTester tester, String action) async {
  await tester.tap(find.text(action));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('UnitActions.createFolder property creates inside the folder', (
    tester,
  ) async {
    final names = <String>[];
    forAll(wordOf, names.add, runs: 4);

    for (final name in names) {
      final backend = FakeBackend({'/create-folder': answerWith({})});
      var changes = 0;
      final actions = UnitActions(
        api: FoldersApi(backend.client()),
        folderId: 'current-folder',
        onChanged: () => changes++,
      );

      await tester.pumpWidget(_actionsHost(actions, _generatedUnits(1).single));
      await _run(tester, 'run create');
      await tester.enterText(find.byType(TextField), name);
      await tester.pump();
      await _run(tester, 'Create');

      expect(sentBody(backend.received.single), {
        'parent_folder_id': 'current-folder',
        'folder_name': name,
      });
      expect(changes, 1);
    }
  });

  testWidgets('UnitActions.rename property renames and reports a change', (
    tester,
  ) async {
    for (final unit in _generatedUnits(4)) {
      final backend = FakeBackend({'/rename-unit': answerWith({})});
      var changes = 0;
      final actions = UnitActions(
        api: FoldersApi(backend.client()),
        folderId: 'current-folder',
        onChanged: () => changes++,
      );

      await tester.pumpWidget(_actionsHost(actions, unit));
      await _run(tester, 'run rename');
      await tester.enterText(find.byType(TextField), 'Renamed ${unit.name}');
      await _run(tester, 'Save name');

      expect(sentBody(backend.received.single)['name'], 'Renamed ${unit.name}');
      expect(changes, 1);
    }
  });

  testWidgets('UnitActions.move property moves into the chosen folder', (
    tester,
  ) async {
    for (final unit in _generatedUnits(4)) {
      final backend = FakeBackend({'/move-unit': answerWith({})});
      var changes = 0;
      final actions = UnitActions(
        api: FoldersApi(backend.client()),
        folderId: 'current-folder',
        onChanged: () => changes++,
      );

      await tester.pumpWidget(_actionsHost(actions, unit));
      await _run(tester, 'run move');
      await _run(tester, 'Target');

      expect(sentBody(backend.received.single)['folder_id'], 'target-folder');
      expect(changes, 1);
    }
  });

  testWidgets('UnitActions.delete property deletes only after confirming', (
    tester,
  ) async {
    for (final unit in _generatedUnits(4)) {
      final backend = FakeBackend({unit.type.deletePath: answerWith({})});
      var changes = 0;
      final actions = UnitActions(
        api: FoldersApi(backend.client()),
        folderId: 'current-folder',
        onChanged: () => changes++,
      );

      await tester.pumpWidget(_actionsHost(actions, unit));
      await _run(tester, 'run delete');
      await _run(tester, 'Cancel');

      expect(backend.received, isEmpty);

      await _run(tester, 'run delete');
      await _run(tester, 'Delete ${unitNoun(unit.type)}');

      expect(backend.received.single.method, 'DELETE');
      expect(changes, 1);
    }
  });

  testWidgets('UnitActions property shows a refusal and changes nothing', (
    tester,
  ) async {
    final details = <String>[];
    forAll((random) => 'Refused ${wordOf(random)}', details.add, runs: 4);

    for (final detail in details) {
      final backend = FakeBackend({
        '/rename-unit': (request) async =>
            http.Response('{"detail":"$detail"}', 422),
      });
      var changes = 0;
      final actions = UnitActions(
        api: FoldersApi(backend.client()),
        folderId: 'current-folder',
        onChanged: () => changes++,
      );

      await tester.pumpWidget(_actionsHost(actions, _generatedUnits(1).single));
      await _run(tester, 'run rename');
      await tester.enterText(find.byType(TextField), 'New name');
      await _run(tester, 'Save name');

      expect(find.text(detail), findsOneWidget);
      expect(changes, 0);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
  });
}
