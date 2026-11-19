import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/folders/folder_models.dart';
import 'package:leffic/features/folders/unit_menu.dart';
import 'package:leffic/features/folders/unit_presentation.dart';
import 'package:leffic/shared/design/design_dropdown.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';

import '../../support/property.dart';
import 'folder_fakes.dart';

const Set<UnitType> _reviewableTypes = {UnitType.flashcardDeck, UnitType.test};

class _MenuCalls {
  final List<String> calls = [];

  List<DropdownEntry> entriesFor(FolderUnit unit) {
    return unitMenuEntries(
      unit: unit,
      onReview: () => calls.add('review'),
      onMove: () => calls.add('move'),
      onRename: () => calls.add('rename'),
      onDelete: () => calls.add('delete'),
    );
  }
}

List<DropdownAction> _actionsOf(List<DropdownEntry> entries) {
  final actions = <DropdownAction>[];

  for (final entry in entries) {
    if (entry is DropdownAction) {
      actions.add(entry);
    }
  }

  return actions;
}

List<FolderUnit> _generatedUnits() {
  return examplesOf(
    (random) => FolderUnit.fromJson(generatedUnitJson(random, 'unit')),
    runs: 40,
  );
}

void main() {
  test('unitMenuEntries property offers a review only for decks and tests', () {
    for (final unit in _generatedUnits()) {
      final labels = [
        for (final action in _actionsOf(_MenuCalls().entriesFor(unit)))
          action.label,
      ];

      expect(
        labels.contains('Review now'),
        _reviewableTypes.contains(unit.type),
      );
      expect(labels, containsAllInOrder(['Move to folder', 'Rename']));
    }
  });

  test('unitMenuEntries property ends with a separated danger delete', () {
    for (final unit in _generatedUnits()) {
      final entries = _MenuCalls().entriesFor(unit);
      final delete = entries.last as DropdownAction;

      expect(entries[entries.length - 2], isA<DropdownSeparator>());
      expect(delete.label, 'Delete ${unitNoun(unit.type)}');
      expect(delete.tone, DropdownTone.danger);
      expect(delete.icon, DesignIcons.trash);
    }
  });

  test('unitMenuEntries property routes each action to its callback', () {
    for (final unit in _generatedUnits()) {
      final menu = _MenuCalls();

      for (final action in _actionsOf(menu.entriesFor(unit))) {
        action.onSelected();
      }

      final expected = [
        if (_reviewableTypes.contains(unit.type)) 'review',
        'move',
        'rename',
        'delete',
      ];

      expect(menu.calls, expected);
    }
  });
}
