import '../../shared/navigation/routes.dart';
import 'folder_models.dart';

typedef UnitRoute = ({String name, Object arguments});

UnitRoute routeForUnit(FolderUnit unit) {
  final unitArguments = UnitArguments(id: unit.id, name: unit.name);

  return switch (unit.type) {
    UnitType.folder => (name: Routes.folder, arguments: unitArguments),
    UnitType.flashcardDeck => (
      name: Routes.deckReview,
      arguments: unitArguments,
    ),
    UnitType.test => (name: Routes.test, arguments: unitArguments),
    UnitType.note => (name: Routes.note, arguments: unitArguments),
    UnitType.file => (
      name: Routes.file,
      arguments: FileArguments(
        id: unit.id,
        name: unit.name,
        extension: unit.extension,
      ),
    ),
  };
}
