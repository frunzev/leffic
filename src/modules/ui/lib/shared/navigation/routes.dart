abstract final class Routes {
  static const String startup = '/';
  static const String folder = '/folder';
  static const String deckReview = '/flashcard-deck';
  static const String folderReview = '/folder-flashcards';
  static const String test = '/test';
  static const String folderTest = '/folder-test';
  static const String note = '/note';
  static const String file = '/file';
  static const String settings = '/settings';
}

const String homeFolderId = 'home';

class UnitArguments {
  const UnitArguments({required this.id, this.name = ''});

  final String id;
  final String name;
}

class FileArguments {
  const FileArguments({
    required this.id,
    required this.name,
    required this.extension,
  });

  final String id;
  final String name;
  final String extension;
}
