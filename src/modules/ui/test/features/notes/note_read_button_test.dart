import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/notes/note_read_button.dart';
import 'package:leffic/shared/api/api_error.dart';
import 'package:leffic/shared/design/button_look.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

DesignButton _shownButton(WidgetTester tester) {
  return tester.widget<DesignButton>(find.byType(DesignButton));
}

bool _isMarkedAsReadButton(Widget widget) {
  if (widget is! DesignButton) {
    return false;
  }

  final isDoneLook = widget.variant == ButtonVariant.done;
  final isMarkedAsRead = widget.label == 'Marked as read';
  final isInert = widget.onPressed == null;

  return isDoneLook && isMarkedAsRead && isInert;
}

final Finder _markedAsRead = find.byWidgetPredicate(_isMarkedAsReadButton);

void main() {
  testWidgets('NoteReadButton property marks an unread note read once', (
    tester,
  ) async {
    for (final extraTaps in examplesOf(
      (random) => integerBetween(random, 0, 3),
      runs: 5,
    )) {
      final pendingMark = Completer<void>();
      var markCount = 0;

      await tester.pumpWidget(
        hostedPlainly(
          NoteReadButton(
            initialState: NoteReadState.unread,
            markRead: () {
              markCount++;

              return pendingMark.future;
            },
          ),
        ),
      );

      final unreadButton = _shownButton(tester);

      expect(unreadButton.label, 'Mark as read');
      expect(unreadButton.icon, DesignIcons.check);
      expect(unreadButton.variant, ButtonVariant.primary);

      await tester.tap(find.text('Mark as read'));
      await tester.pump();

      for (var tap = 0; tap < extraTaps; tap++) {
        await tester.tap(find.text('Marking…'));
        await tester.pump();
      }

      expect(_shownButton(tester).onPressed, isNull);

      pendingMark.complete();
      await tester.pumpAndSettle();

      expect(markCount, 1);
      expect(_markedAsRead, findsOneWidget);
      expect(_shownButton(tester).icon, DesignIcons.success);
    }
  });

  testWidgets('NoteReadButton property offers the mark again after failing', (
    tester,
  ) async {
    for (final detail in examplesOf(wordOf, runs: 4)) {
      await tester.pumpWidget(
        hostedPlainly(
          NoteReadButton(
            initialState: NoteReadState.unread,
            markRead: () async {
              throw ApiError(
                statusCode: 500,
                path: '/review-note',
                detail: detail,
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Mark as read'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't mark the note as read"), findsOneWidget);
      expect(
        find.text('The note stayed in your due list. Try again.'),
        findsOneWidget,
      );
      expect(_shownButton(tester).onPressed, isNotNull);
      expect(_markedAsRead, findsNothing);
    }
  });

  testWidgets('NoteReadButton property never marks a read note again', (
    tester,
  ) async {
    for (final taps in examplesOf(
      (random) => integerBetween(random, 1, 3),
      runs: 3,
    )) {
      var markCount = 0;

      await tester.pumpWidget(
        hostedPlainly(
          NoteReadButton(
            initialState: NoteReadState.read,
            markRead: () async {
              markCount++;
            },
          ),
        ),
      );

      for (var tap = 0; tap < taps; tap++) {
        await tester.tap(find.text('Marked as read'));
        await tester.pump();
      }

      expect(markCount, 0);
      expect(_markedAsRead, findsOneWidget);
    }
  });
}
