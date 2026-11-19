import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/notes/note_foot.dart';
import 'package:leffic/features/notes/note_models.dart';
import 'package:leffic/features/notes/note_read_button.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_colors.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

String _hintFor(NotesProgress progress) {
  return 'Read ${progress.read} of ${progress.total} notes in this folder.';
}

NotesProgress _generatedProgress(int read, int unread) {
  return NotesProgress(read: read, total: read + unread);
}

Widget _footIn(
  Brightness brightness,
  NotesProgress progress,
  Future<void> Function() markRead,
) {
  return hostedInTheme(
    Align(
      alignment: Alignment.topLeft,
      child: NoteFoot(
        initialReadState: NoteReadState.unread,
        initialProgress: progress,
        markRead: markRead,
      ),
    ),
    brightness: brightness,
  );
}

Future<void> _failToMark() async {
  throw Exception('offline');
}

void main() {
  testWidgets('NoteFoot property counts the note once it is marked read', (
    tester,
  ) async {
    for (final (read, unread) in examplesOf(
      (random) => (integerBetween(random, 0, 40), integerBetween(random, 1, 9)),
      runs: 6,
    )) {
      final progress = _generatedProgress(read, unread);

      await tester.pumpWidget(_footIn(Brightness.light, progress, () async {}));

      expect(find.text(_hintFor(progress)), findsOneWidget);

      await tester.tap(find.text('Mark as read'));
      await tester.pumpAndSettle();

      expect(find.text(_hintFor(progress.afterOneMoreRead())), findsOneWidget);
      expect(find.text('Marked as read'), findsOneWidget);
    }
  });

  testWidgets('NoteFoot property keeps the count when marking fails', (
    tester,
  ) async {
    for (final (read, unread) in examplesOf(
      (random) => (integerBetween(random, 0, 40), integerBetween(random, 1, 9)),
      runs: 4,
    )) {
      final progress = _generatedProgress(read, unread);

      await tester.pumpWidget(_footIn(Brightness.light, progress, _failToMark));
      await tester.tap(find.text('Mark as read'));
      await tester.pumpAndSettle();

      expect(find.text(_hintFor(progress)), findsOneWidget);
      expect(find.text('Mark as read'), findsOneWidget);
    }
  });

  testWidgets('NoteFoot property lays out the .note-foot row', (tester) async {
    for (final brightness in Brightness.values) {
      const progress = NotesProgress(read: 12, total: 13);
      final colors = DesignColors.forBrightness(brightness);

      await tester.pumpWidget(_footIn(brightness, progress, () async {}));

      final button = tester.getRect(find.byType(DesignButton));
      final hint = tester.getRect(find.text(_hintFor(progress)));
      final hintStyle = renderedStyleOf(tester, _hintFor(progress));

      expect(hint.left, button.right + 12);
      expect(hint.center.dy, moreOrLessEquals(button.center.dy));
      expect(hintStyle.fontSize, 14);
      expect(hintStyle.color, colors.inkTertiary);
    }
  });
}
