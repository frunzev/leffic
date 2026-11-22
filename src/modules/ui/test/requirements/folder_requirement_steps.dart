import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/folders/folder_page.dart';
import 'package:leffic/shared/navigation/routes.dart';

import '../features/folders/folder_fakes.dart';
import '../support/backend_fakes.dart';
import '../support/hosting.dart';
import 'requirement_world.dart';
import 'step_definition.dart';

const String _createdAt = '2026-11-01 08:00:00';
const String _accessFolder = '/access-folder/';
const int _missingStatus = 404;

Map<String, Object?> _listing(
  String folderName,
  List<Map<String, Object?>> units,
) {
  return {
    'parent_folder_name': folderName,
    'content': units,
    'ancestors': <Object?>[],
  };
}

Map<String, Object?> _deckUnit(String deckName) {
  return {
    'id': 'deck-$deckName',
    'name': deckName,
    'type': 'flashcard_deck',
    'created_at': _createdAt,
    'card_count': 1,
    'due_count': 1,
  };
}

Map<String, Object?> _noteUnit(String noteName) {
  return {
    'id': 'note-$noteName',
    'name': noteName,
    'type': 'note',
    'created_at': _createdAt,
    'reading_minutes': 1,
  };
}

Future<void> _serveFolderWithUnits(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final [folderName, deckName, noteName] = values;
  final units = [_deckUnit(deckName), _noteUnit(noteName)];

  world.replies.addAll(folderReplies(_listing(folderName, units)));
}

Future<void> _serveEmptyFolder(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  world.replies.addAll(folderReplies(_listing(values.single, [])));
}

Future<void> _refuseFolder(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final [_, refusal] = values;

  world.replies[_accessFolder] = failWith(_missingStatus, refusal);
}

Future<void> _openFolder(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final folderName = values.single;
  final arguments = UnitArguments(id: 'folder-$folderName', name: folderName);

  await tester.pumpWidget(
    hostedWithBackend(
      client: world.client(),
      opened: [],
      child: FolderPage(arguments: arguments),
    ),
  );
  await tester.pumpAndSettle();
}

final List<StepDefinition> folderStepDefinitions = [
  StepDefinition(
    'Given',
    RegExp(
      r'^the backend has the folder "(.+)" '
      r'holding the deck "(.+)" and the note "(.+)"$',
    ),
    _serveFolderWithUnits,
  ),
  StepDefinition(
    'Given',
    RegExp(r'^the backend has the empty folder "(.+)"$'),
    _serveEmptyFolder,
  ),
  StepDefinition(
    'Given',
    RegExp(r'^the backend refuses the folder "(.+)" with "(.+)"$'),
    _refuseFolder,
  ),
  StepDefinition(
    'When',
    RegExp(r'^I open the folder "(.+)" in the app$'),
    _openFolder,
  ),
];
