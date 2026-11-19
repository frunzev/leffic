import 'dart:math';

import 'package:leffic/features/folders/folder_models.dart';

import '../../support/property.dart';

const String crumbHome = 'Home';
const FolderAncestor rootAncestor = FolderAncestor(
  id: 'root-folder',
  name: 'Home',
);

List<FolderAncestor> generatedAncestors(Random random) {
  final depth = integerBetween(random, 0, 3);
  final ancestors = <FolderAncestor>[];

  for (var level = 0; level < depth; level++) {
    final ancestor = level == 0
        ? rootAncestor
        : FolderAncestor(
            id: 'ancestor-$level',
            name: 'Level$level ${wordOf(random, maximum: 5)}',
          );

    ancestors.add(ancestor);
  }

  return ancestors;
}
