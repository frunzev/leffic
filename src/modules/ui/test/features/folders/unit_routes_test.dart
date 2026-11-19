import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/folders/folder_models.dart';
import 'package:leffic/features/folders/unit_routes.dart';
import 'package:leffic/shared/navigation/routes.dart';

import '../../support/property.dart';
import 'folder_fakes.dart';

const Map<UnitType, String> _expectedRoutes = {
  UnitType.folder: Routes.folder,
  UnitType.flashcardDeck: Routes.deckReview,
  UnitType.test: Routes.test,
  UnitType.note: Routes.note,
  UnitType.file: Routes.file,
};

void main() {
  test('routeForUnit property opens the route of the unit type', () {
    forAll((random) => generatedUnitJson(random, tokenOf(random)), (json) {
      final unit = FolderUnit.fromJson(json);
      final route = routeForUnit(unit);

      expect(route.name, _expectedRoutes[unit.type]);
    });
  });

  test('routeForUnit property hands the unit identity to the route', () {
    forAll((random) => generatedUnitJson(random, tokenOf(random)), (json) {
      final unit = FolderUnit.fromJson(json);
      final arguments = routeForUnit(unit).arguments;

      switch (arguments) {
        case FileArguments():
          expect(unit.type, UnitType.file);
          expect(arguments.id, unit.id);
          expect(arguments.name, unit.name);
          expect(arguments.extension, unit.extension);
        case UnitArguments():
          expect(unit.type, isNot(UnitType.file));
          expect(arguments.id, unit.id);
          expect(arguments.name, unit.name);
        default:
          fail('Unexpected arguments $arguments');
      }
    });
  });
}
