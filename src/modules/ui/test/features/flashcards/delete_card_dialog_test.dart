import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/flashcards/delete_card_dialog.dart';
import 'package:leffic/shared/design/button_look.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_modal.dart';
import 'package:leffic/shared/design/icons/design_icon.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';
import 'dialog_opening.dart';
import 'flashcard_generators.dart';

const String _deletionWarning =
    'Its review history goes too, so this cannot be undone. '
    'The rest of the deck is untouched.';

Finder _decorationAround(String text) {
  return find
      .ancestor(of: find.text(text), matching: find.byType(DecoratedBox))
      .first;
}

void main() {
  testWidgets('confirmCardDeletion property is true only on Delete card', (
    tester,
  ) async {
    final examples = examplesOf(
      (random) => (
        oneOf(random, ['Delete card', 'Keep card', 'Close dialog']),
        generatedSentence(random),
      ),
      runs: 8,
    );

    for (final (button, question) in examples) {
      final answers = <Object?>[];

      await tester.pumpWidget(
        openingDialog(
          (context) => confirmCardDeletion(context, question: question),
          answers,
        ),
      );
      await openDialog(tester);

      expect(find.text('Delete this card?'), findsOneWidget);
      expect(find.text('It leaves the deck for good.'), findsOneWidget);
      expect(find.text(question), findsOneWidget);

      if (button == 'Close dialog') {
        await tester.tap(find.bySemanticsLabel(button));
      } else {
        await tester.tap(find.text(button));
      }

      await tester.pumpAndSettle();

      expect(answers, [button == 'Delete card']);
    }
  });

  testWidgets('DeleteCardDialog property names the card, then warns', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final question in examplesOf(generatedSentence, runs: 4)) {
      useDesktopSurface(tester);
      await tester.pumpWidget(
        hostedPlainly(Center(child: DeleteCardDialog(question: question))),
      );

      final modal = tester.widget<DesignModal>(find.byType(DesignModal));
      final subjectBox = tester.getRect(_decorationAround(question));
      final subjectText = tester.getRect(find.text(question));
      final subjectDecoration =
          tester.widget<DecoratedBox>(_decorationAround(question)).decoration
              as BoxDecoration;
      final warningBox = tester.getRect(_decorationAround(_deletionWarning));
      final warningText = tester.getRect(find.text(_deletionWarning));
      final warningDecoration =
          tester
                  .widget<DecoratedBox>(_decorationAround(_deletionWarning))
                  .decoration
              as BoxDecoration;
      final warningIcon = tester.widget<DesignIcon>(
        find.descendant(
          of: _decorationAround(_deletionWarning),
          matching: find.byType(DesignIcon),
        ),
      );
      final actions = tester
          .widgetList<DesignButton>(find.byType(DesignButton))
          .toList();

      expect(modal.title, 'Delete this card?');
      expect(modal.description, 'It leaves the deck for good.');
      expect(modal.width, ModalWidth.wide);
      expect(renderedStyleOf(tester, question).fontSize, 14);
      expect(renderedStyleOf(tester, question).color, colors.ink);
      expect(
        subjectDecoration.border,
        Border(left: BorderSide(color: colors.line, width: 2)),
      );
      expect(subjectText.left - subjectBox.left, 18);
      expect(subjectText.top - subjectBox.top, 12);
      expect(warningBox.top - subjectBox.bottom, 16);
      expect(warningDecoration.color, colors.surfaceSecondary);
      expect(warningDecoration.border, Border.all(color: colors.line));
      expect(warningDecoration.borderRadius, BorderRadius.circular(10));
      expect(warningText.left - warningBox.left, 47);
      expect(warningText.top - warningBox.top, 13);
      expect(renderedStyleOf(tester, _deletionWarning).fontSize, 14);
      expect(
        renderedStyleOf(tester, _deletionWarning).color,
        colors.inkSecondary,
      );
      expect(warningIcon.icon, DesignIcons.failure);
      expect(warningIcon.size, 18);
      expect(warningIcon.color, colors.danger);
      expect(actions.map((action) => action.label), [
        'Keep card',
        'Delete card',
      ]);
      expect(actions.map((action) => action.variant), [
        ButtonVariant.standard,
        ButtonVariant.danger,
      ]);
    }
  });
}
