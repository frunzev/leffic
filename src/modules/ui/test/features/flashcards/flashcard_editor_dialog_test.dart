import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/flashcards/face_editing.dart';
import 'package:leffic/features/flashcards/flashcard_editor_dialog.dart';
import 'package:leffic/features/flashcards/flashcard_faces.dart';
import 'package:leffic/shared/design/button_look.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_field.dart';
import 'package:leffic/shared/design/design_modal.dart';
import 'package:leffic/shared/design/design_text_field.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import 'dialog_opening.dart';
import 'flashcard_generators.dart';

Finder _fieldLabelled(String label) {
  return find.descendant(
    of: find.widgetWithText(DesignField, label),
    matching: find.byType(TextField),
  );
}

void main() {
  testWidgets('showFlashcardEditor property answers the edited face', (
    tester,
  ) async {
    final examples = examplesOf(
      (random) => (
        generatedFace(random),
        generatedSentence(random),
        generatedWords(random).join('\n'),
      ),
      runs: 8,
    );

    for (final (face, firstText, secondText) in examples) {
      final answers = <Object?>[];
      final fields = editableFieldsOf(face);

      await tester.pumpWidget(
        openingDialog(
          (context) => showFlashcardEditor(context: context, face: face),
          answers,
        ),
      );
      await openDialog(tester);
      await tester.enterText(_fieldLabelled(fields.firstLabel), firstText);
      await tester.enterText(_fieldLabelled(fields.secondLabel), secondText);
      await tester.pump();
      await tester.tap(find.text('Save card'));
      await tester.pumpAndSettle();

      final expected = faceEditedWith(
        face,
        firstText: firstText,
        secondText: secondText,
      );
      final saved = answers.single! as FlashcardFace;

      expect(saved.toContent(), expected.toContent());
    }
  });

  testWidgets('FlashcardEditorDialog property refuses an incomplete card', (
    tester,
  ) async {
    for (final face in examplesOf(generatedFace, runs: 6)) {
      final answers = <Object?>[];
      final fields = editableFieldsOf(face);

      await tester.pumpWidget(
        openingDialog(
          (context) => showFlashcardEditor(context: context, face: face),
          answers,
        ),
      );
      await openDialog(tester);
      await tester.enterText(_fieldLabelled(fields.firstLabel), '   ');
      await tester.pump();
      await tester.tap(find.text('Save card'));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(answers, [null]);
    }
  });

  testWidgets('FlashcardEditorDialog property is the wide edit modal', (
    tester,
  ) async {
    for (final face in examplesOf(generatedFace, runs: 6)) {
      final fields = editableFieldsOf(face);

      useDesktopSurface(tester);
      await tester.pumpWidget(
        openingDialog(
          (context) => showFlashcardEditor(context: context, face: face),
          [],
        ),
      );
      await openDialog(tester);

      final modal = tester.widget<DesignModal>(find.byType(DesignModal));
      final labels = tester
          .widgetList<DesignField>(find.byType(DesignField))
          .map((field) => field.label);
      final areas = find.byType(DesignTextArea);
      final firstArea = tester.getRect(areas.first);
      final secondLabel = tester.getRect(find.text(fields.secondLabel));
      final firstInput = tester.widget<TextField>(
        _fieldLabelled(fields.firstLabel),
      );

      expect(modal.title, 'Edit flashcard');
      expect(
        modal.description,
        'Changes apply the next time this card comes up.',
      );
      expect(modal.width, ModalWidth.wide);
      expect(labels, [fields.firstLabel, fields.secondLabel]);
      expect(areas, findsNWidgets(2));
      expect(secondLabel.top - firstArea.bottom, 16);
      expect(firstInput.focusNode?.hasFocus ?? false, isFalse);

      final actions = tester
          .widgetList<DesignButton>(find.byType(DesignButton))
          .toList();

      expect(actions.map((action) => action.label), ['Cancel', 'Save card']);
      expect(actions.map((action) => action.variant), [
        ButtonVariant.standard,
        ButtonVariant.primary,
      ]);
    }
  });
}
