import 'icon_shape.dart';
import 'icon_shapes_content.dart';
import 'icon_shapes_shell.dart';
import 'icon_shapes_study.dart';

enum DesignIcons {
  mnemonic(mnemonicShape),
  bookmark(bookmarkShape),
  logo(logoShape),
  home(homeShape),
  ask(askShape),
  profile(profileShape),
  logout(logoutShape),
  settings(settingsShape),
  study(studyShape),
  flashcards(flashcardsShape),
  test(testShape),
  folder(folderShape),
  folderOpen(folderOpenShape),
  file(fileShape),
  note(noteShape),
  aiImport(aiImportShape),
  newFolder(newFolderShape),
  fileSmall(fileSmallShape),
  link(linkShape),
  topic(topicShape),
  dots(dotsShape),
  trash(trashShape),
  close(closeShape),
  closePlain(closePlainShape),
  plus(plusShape),
  chatHeader(chatHeaderShape),
  success(successShape),
  failure(failureShape),
  check(checkShape),
  chevronRight(chevronRightShape),
  send(sendShape),
  start(startShape);

  const DesignIcons(this.shape);

  final IconShape shape;
}
