import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/folders/folder_models.dart';
import 'package:leffic/features/folders/unit_details.dart';
import 'package:leffic/shared/navigation/routes.dart';

import '../../support/property.dart';
import 'folder_fakes.dart';

List<FolderUnit> _unitsFrom(List<Map<String, Object?>> jsons) {
  final units = <FolderUnit>[];

  for (final json in jsons) {
    units.add(FolderUnit.fromJson(json));
  }

  return units;
}

void main() {
  test('UnitType.fromWireName property round-trips every wire name', () {
    forAll((random) => oneOf(random, UnitType.values), (type) {
      expect(UnitType.fromWireName(type.wireName), type);
    });
  });

  test('UnitType.fromWireName property refuses unknown names', () {
    forAll((random) => '${wordOf(random)}_unknown', (name) {
      expect(() => UnitType.fromWireName(name), throwsFormatException);
    });
  });

  test('FolderUnit.fromJson property keeps every field it was given', () {
    forAll((random) => generatedUnitJson(random, tokenOf(random)), (json) {
      final unit = FolderUnit.fromJson(json);

      expect(unit.id, json['id']);
      expect(unit.name, json['name']);
      expect(unit.type.wireName, json['type']);
      expect(unit.createdAt, DateTime.parse(json['created_at']! as String));
      expect(unit.extension, json['extension'] ?? '');
    });
  });

  test('FolderUnit.fromJson property reads the details of its own type', () {
    forAll((random) => generatedUnitJson(random, tokenOf(random)), (json) {
      final unit = FolderUnit.fromJson(json);
      final detailsType = switch (unit.details) {
        FolderDetails() => UnitType.folder,
        DeckDetails() => UnitType.flashcardDeck,
        TestDetails() => UnitType.test,
        NoteDetails() => UnitType.note,
        FileDetails() => UnitType.file,
      };

      expect(detailsType, unit.type);
    });
  });

  test('FolderAncestor.fromJson property keeps the id and the name', () {
    forAll(generatedAncestorJsons, (jsons) {
      for (final json in jsons) {
        final ancestor = FolderAncestor.fromJson(json);

        expect(ancestor.id, json['id']);
        expect(ancestor.name, json['name']);
      }
    });
  });

  test('FolderUnit.fromJson property fails fast on a missing field', () {
    forAll(
      (random) => (
        generatedUnitJson(random, tokenOf(random)),
        oneOf(random, ['id', 'name', 'type', 'created_at']),
      ),
      (example) {
        final (json, missingKey) = example;
        final broken = Map<String, Object?>.of(json)..remove(missingKey);

        expect(() => FolderUnit.fromJson(broken), throwsFormatException);
      },
    );
  });

  test('FolderListing.fromJson property fails fast without ancestors', () {
    forAll(generatedListingJson, (json) {
      final broken = Map<String, Object?>.of(json)..remove('ancestors');

      expect(() => FolderListing.fromJson(broken), throwsFormatException);
    });
  });

  test('FolderListing.fromJson property lists every unit newest first', () {
    forAll(generatedListingJson, (json) {
      final listing = FolderListing.fromJson(json);
      final content = json['content']! as List<Map<String, Object?>>;
      final expectedIds = [for (final entry in content) entry['id']]..sort();
      final listedIds = [for (final unit in listing.units) unit.id]..sort();

      final ancestors = json['ancestors']! as List<Map<String, Object?>>;

      expect(listing.folderName, json['parent_folder_name']);
      expect(listedIds, expectedIds);
      expect(
        [for (final ancestor in listing.ancestors) ancestor.id],
        [for (final ancestor in ancestors) ancestor['id']],
      );

      for (var index = 1; index < listing.units.length; index++) {
        final newer = listing.units[index - 1].createdAt;
        final older = listing.units[index].createdAt;

        expect(older.isAfter(newer), isFalse);
      }
    });
  });

  test('sortedNewestFirst property is an ordered permutation', () {
    forAll((random) => _unitsFrom(generatedUnitJsons(random)), (units) {
      final sorted = sortedNewestFirst(units);

      expect(sorted.toSet(), units.toSet());
      expect(sorted.length, units.length);

      for (var index = 1; index < sorted.length; index++) {
        final isOrdered = !sorted[index].createdAt.isAfter(
          sorted[index - 1].createdAt,
        );

        expect(isOrdered, isTrue);
      }
    });
  });

  test('sortedNewestFirst property leaves the given list untouched', () {
    forAll((random) => _unitsFrom(generatedUnitJsons(random)), (units) {
      final before = List<FolderUnit>.of(units);

      sortedNewestFirst(units);

      expect(units, before);
    });
  });

  test('moveDestinationsFor property offers only other folders', () {
    forAll(
      (random) => (
        _unitsFrom(generatedUnitJsons(random)),
        oneOf(random, [homeFolderId, 'folder-${tokenOf(random)}']),
      ),
      (example) {
        final (units, currentFolderId) = example;
        final moving = units.first;
        final destinations = moveDestinationsFor(
          currentFolderId: currentFolderId,
          units: units,
          movingUnit: moving,
        );
        final destinationIds = [for (final entry in destinations) entry.id];
        final otherFolderIds = [
          for (final unit in units)
            if (unit.type == UnitType.folder && unit.id != moving.id) unit.id,
        ];
        final isHomeOffered = destinationIds.contains(homeFolderId);

        expect(destinationIds, isNot(contains(moving.id)));
        expect(isHomeOffered, currentFolderId != homeFolderId);
        expect(
          destinationIds.where((id) => id != homeFolderId),
          otherFolderIds,
        );
      },
    );
  });
}
