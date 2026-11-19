import '../../shared/api/json_reading.dart';
import '../../shared/navigation/routes.dart';
import 'unit_details.dart';

typedef DetailsReader = UnitDetails Function(JsonObject json);

const String homeFolderName = 'Home';

enum UnitType {
  folder(
    wireName: 'folder',
    deletePath: '/delete-folder/',
    deleteQueryKey: 'folder_id',
    readDetails: FolderDetails.fromJson,
  ),
  flashcardDeck(
    wireName: 'flashcard_deck',
    deletePath: '/delete-deck/',
    deleteQueryKey: 'deck_id',
    readDetails: DeckDetails.fromJson,
  ),
  test(
    wireName: 'test',
    deletePath: '/delete-test/',
    deleteQueryKey: 'test_id',
    readDetails: TestDetails.fromJson,
  ),
  note(
    wireName: 'note',
    deletePath: '/delete-note/',
    deleteQueryKey: 'note_id',
    readDetails: NoteDetails.fromJson,
  ),
  file(
    wireName: 'file',
    deletePath: '/delete-file/',
    deleteQueryKey: 'file_id',
    readDetails: FileDetails.fromJson,
  );

  const UnitType({
    required this.wireName,
    required this.deletePath,
    required this.deleteQueryKey,
    required this.readDetails,
  });

  final String wireName;
  final String deletePath;
  final String deleteQueryKey;
  final DetailsReader readDetails;

  static UnitType fromWireName(String wireName) {
    for (final type in values) {
      if (type.wireName == wireName) {
        return type;
      }
    }

    throw FormatException('Unknown unit type "$wireName"');
  }
}

class FolderUnit {
  const FolderUnit({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.extension,
    required this.details,
  });

  factory FolderUnit.fromJson(JsonObject json) {
    final type = UnitType.fromWireName(readText(json, 'type'));

    return FolderUnit(
      id: readText(json, 'id'),
      name: readText(json, 'name'),
      type: type,
      createdAt: DateTime.parse(readText(json, 'created_at')),
      extension: readTextOr(json, 'extension', ''),
      details: type.readDetails(json),
    );
  }

  final String id;
  final String name;
  final UnitType type;
  final DateTime createdAt;
  final String extension;
  final UnitDetails details;
}

class FolderAncestor {
  const FolderAncestor({required this.id, required this.name});

  factory FolderAncestor.fromJson(JsonObject json) {
    return FolderAncestor(
      id: readText(json, 'id'),
      name: readText(json, 'name'),
    );
  }

  final String id;
  final String name;
}

const FolderAncestor homeAncestor = FolderAncestor(
  id: homeFolderId,
  name: homeFolderName,
);

class FolderListing {
  const FolderListing({
    required this.folderName,
    required this.units,
    required this.ancestors,
  });

  factory FolderListing.fromJson(JsonObject json) {
    final units = <FolderUnit>[];
    final ancestors = <FolderAncestor>[];

    for (final entry in readObjects(json, 'content')) {
      units.add(FolderUnit.fromJson(entry));
    }

    for (final entry in readObjects(json, 'ancestors')) {
      ancestors.add(FolderAncestor.fromJson(entry));
    }

    return FolderListing(
      folderName: readText(json, 'parent_folder_name'),
      units: sortedNewestFirst(units),
      ancestors: ancestors,
    );
  }

  final String folderName;
  final List<FolderUnit> units;
  final List<FolderAncestor> ancestors;
}

List<FolderUnit> sortedNewestFirst(List<FolderUnit> units) {
  final sorted = List<FolderUnit>.of(units);

  sorted.sort((left, right) => right.createdAt.compareTo(left.createdAt));

  return sorted;
}

class MoveDestination {
  const MoveDestination({required this.id, required this.name});

  final String id;
  final String name;
}

List<MoveDestination> moveDestinationsFor({
  required String currentFolderId,
  required List<FolderUnit> units,
  required FolderUnit movingUnit,
}) {
  final destinations = <MoveDestination>[];

  if (currentFolderId != homeFolderId) {
    destinations.add(
      const MoveDestination(id: homeFolderId, name: homeFolderName),
    );
  }

  for (final unit in units) {
    final isOtherFolder =
        unit.type == UnitType.folder && unit.id != movingUnit.id;

    if (isOtherFolder) {
      destinations.add(MoveDestination(id: unit.id, name: unit.name));
    }
  }

  return destinations;
}
