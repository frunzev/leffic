import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/folders/delete_unit_dialog.dart';
import 'package:leffic/features/folders/folder_models.dart';
import 'package:leffic/features/folders/move_unit_dialog.dart';
import 'package:leffic/features/folders/name_prompt_dialog.dart';
import 'package:leffic/features/folders/unit_presentation.dart';
import 'package:leffic/shared/design/button_look.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_dropdown.dart';
import 'package:leffic/shared/design/design_field.dart';
import 'package:leffic/shared/design/design_modal.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import 'folder_fakes.dart';

typedef _DialogOpener = Future<Object?> Function(BuildContext context);

const NamePrompt _createPrompt = NamePrompt(
  title: 'Create a folder',
  description: 'Folders keep related study units together.',
  fieldLabel: 'Folder name',
  placeholder: 'e.g. Neuroscience',
  confirmLabel: 'Create',
);

Widget _opening(_DialogOpener open, List<Object?> answers) {
  return hostedPlainly(
    Builder(
      builder: (context) => TextButton(
        onPressed: () async => answers.add(await open(context)),
        child: const Text('open dialog'),
      ),
    ),
  );
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text('open dialog'));
  await tester.pumpAndSettle();
}

FolderUnit _unitOfType(UnitType type, String name) {
  final json = unitJsonOfType(
    Random(fixedSeed),
    id: 'unit',
    type: type.wireName,
  );

  return FolderUnit.fromJson({...json, 'name': name});
}

DesignButton _buttonLabelled(WidgetTester tester, String label) {
  return tester.widget<DesignButton>(
    find.ancestor(of: find.text(label), matching: find.byType(DesignButton)),
  );
}

void main() {
  testWidgets('showNamePrompt property answers the trimmed typed name', (
    tester,
  ) async {
    for (final name in examplesOf(wordOf, runs: 5)) {
      final answers = <Object?>[];

      await tester.pumpWidget(
        _opening(
          (context) => showNamePrompt(
            context: context,
            prompt: const NamePrompt(
              title: 'Rename',
              fieldLabel: 'Name',
              confirmLabel: 'Save name',
              initialName: 'old',
            ),
          ),
          answers,
        ),
      );
      await _openDialog(tester);

      expect(find.text('old'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '  $name  ');
      await tester.pump();
      await tester.tap(find.text('Save name'));
      await tester.pumpAndSettle();

      expect(answers, [name]);
    }
  });

  testWidgets('NamePromptDialog property draws the new folder modal', (
    tester,
  ) async {
    final answers = <Object?>[];

    await tester.pumpWidget(
      _opening(
        (context) => showNamePrompt(context: context, prompt: _createPrompt),
        answers,
      ),
    );
    await _openDialog(tester);

    final modal = tester.widget<DesignModal>(find.byType(DesignModal));
    final field = tester.widget<DesignField>(find.byType(DesignField));

    expect(modal.title, 'Create a folder');
    expect(modal.description, 'Folders keep related study units together.');
    expect(modal.width, ModalWidth.regular);
    expect(field.label, 'Folder name');
    expect(find.text('e.g. Neuroscience'), findsOneWidget);
    expect(_buttonLabelled(tester, 'Cancel').variant, ButtonVariant.standard);
    expect(_buttonLabelled(tester, 'Create').variant, ButtonVariant.primary);
    expect(_buttonLabelled(tester, 'Create').onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Neuroscience');
    await tester.pump();

    expect(_buttonLabelled(tester, 'Create').onPressed, isNotNull);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(answers, ['Neuroscience']);
  });

  testWidgets('NamePromptDialog property refuses a blank name', (tester) async {
    for (final blank in examplesOf(
      (random) => ' ' * random.nextInt(4),
      runs: 5,
    )) {
      final answers = <Object?>[];

      await tester.pumpWidget(
        _opening(
          (context) => showNamePrompt(context: context, prompt: _createPrompt),
          answers,
        ),
      );
      await _openDialog(tester);
      await tester.enterText(find.byType(TextField), blank);
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(_buttonLabelled(tester, 'Create').onPressed, isNull);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(answers, [null]);
    }
  });

  testWidgets('showMoveUnitDialog property answers the chosen folder', (
    tester,
  ) async {
    for (final count in examplesOf(
      (random) => integerBetween(random, 1, 4),
      runs: 5,
    )) {
      final destinations = [
        for (var index = 0; index < count; index++)
          MoveDestination(id: 'id-$index', name: 'Folder $index'),
      ];
      final chosen = destinations.last;
      final answers = <Object?>[];

      await tester.pumpWidget(
        _opening(
          (context) => showMoveUnitDialog(
            context: context,
            unitName: 'Biology',
            destinations: destinations,
          ),
          answers,
        ),
      );
      await _openDialog(tester);

      final rows = tester.widgetList<DropdownItem>(find.byType(DropdownItem));

      expect(
        tester.widget<DesignModal>(find.byType(DesignModal)).title,
        'Move Biology',
      );
      expect(
        [for (final row in rows) row.label],
        [for (final destination in destinations) destination.name],
      );
      expect({for (final row in rows) row.icon}, {DesignIcons.folder});

      await tester.tap(find.text(chosen.name));
      await tester.pumpAndSettle();

      expect(answers, [chosen.id]);
    }
  });

  testWidgets('MoveUnitDialog property explains when nowhere is left', (
    tester,
  ) async {
    final answers = <Object?>[];

    await tester.pumpWidget(
      _opening(
        (context) => showMoveUnitDialog(
          context: context,
          unitName: 'Biology',
          destinations: const [],
        ),
        answers,
      ),
    );
    await _openDialog(tester);

    expect(
      find.text('There is no other folder to move it to.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(answers, [null]);
  });

  testWidgets('confirmUnitDeletion property is true only on delete', (
    tester,
  ) async {
    for (final (type, choice) in examplesOf(
      (random) => (
        oneOf(random, UnitType.values),
        oneOf(random, ['delete', 'cancel', 'close']),
      ),
      runs: 10,
    )) {
      final answers = <Object?>[];
      final unit = _unitOfType(type, 'Chemistry');
      final deleteLabel = 'Delete ${unitNoun(type)}';

      await tester.pumpWidget(
        _opening(
          (context) => confirmUnitDeletion(context: context, unit: unit),
          answers,
        ),
      );
      await _openDialog(tester);

      expect(find.text('Delete Chemistry?'), findsOneWidget);
      expect(
        _buttonLabelled(tester, deleteLabel).variant,
        ButtonVariant.danger,
      );

      final target = switch (choice) {
        'delete' => find.text(deleteLabel),
        'cancel' => find.text('Cancel'),
        _ => find.bySemanticsLabel('Close dialog'),
      };

      await tester.tap(target);
      await tester.pumpAndSettle();

      expect(answers, [choice == 'delete']);
    }
  });

  testWidgets('DeleteUnitDialog property warns that folder contents go', (
    tester,
  ) async {
    for (final type in UnitType.values) {
      await tester.pumpWidget(
        hostedPlainly(DeleteUnitDialog(unit: _unitOfType(type, 'Physics'))),
      );

      final modal = tester.widget<DesignModal>(find.byType(DesignModal));
      final expectedWarning = type == UnitType.folder
          ? 'Everything inside it is deleted too.'
          : 'This cannot be undone.';

      expect(modal.description, expectedWarning);
    }
  });
}
