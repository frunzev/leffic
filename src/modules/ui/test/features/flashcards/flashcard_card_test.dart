import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/flashcards/card_menu.dart';
import 'package:leffic/features/flashcards/flashcard_card.dart';
import 'package:leffic/shared/design/button_look.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_dropdown.dart';
import 'package:leffic/shared/design/design_shadows.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';
import 'package:leffic/shared/design/surface_box.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

const Key _menuKey = Key('card menu');
const String _mnemonicLabel = 'Ask for a way to memorise this card';
const String _actionsLabel = 'Actions for this card';

Key _faceKey(int index) => Key('face $index');

Widget _cardOf({required double width, required List<double> faceHeights}) {
  return Center(
    child: SizedBox(
      width: width,
      child: FlashcardCard(
        faces: [
          for (var index = 0; index < faceHeights.length; index++)
            SizedBox(key: _faceKey(index), height: faceHeights[index]),
        ],
        menu: const SizedBox(key: _menuKey, width: 84, height: 40),
      ),
    ),
  );
}

void main() {
  testWidgets('FlashcardCard property is the .flashcard surface and faces', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);
    final shadows = DesignShadows.forBrightness(Brightness.light);
    final examples = examplesOf(
      (random) => (
        integerBetween(random, 400, 720).toDouble(),
        [
          for (var face = 0; face < integerBetween(random, 1, 2); face++)
            integerBetween(random, 40, 240).toDouble(),
        ],
      ),
      runs: 8,
    );

    for (final (width, faceHeights) in examples) {
      await tester.pumpWidget(
        hostedPlainly(_cardOf(width: width, faceHeights: faceHeights)),
      );

      final card = tester.getRect(find.byType(FlashcardCard));
      final surface = tester.widget<SurfaceBox>(find.byType(SurfaceBox));
      var faceTop = card.top + 1;

      expect(surface.look.fill, colors.surface);
      expect(surface.look.border, BorderSide(color: colors.line));
      expect(surface.look.shadows, shadows.level2);
      expect(surface.look.edgeHighlight, shadows.edgeHighlight);
      expect(surface.borderRadius, 14);

      for (var index = 0; index < faceHeights.length; index++) {
        final face = tester.getRect(find.byKey(_faceKey(index)));

        expect(face.left, card.left + 1);
        expect(face.width, width - 2);
        expect(face.top, faceTop);

        faceTop = face.bottom;
      }

      expect(card.bottom, faceTop + 1);
    }
  });

  testWidgets('FlashcardCard property pins its menu 12px inside the corner', (
    tester,
  ) async {
    final widths = examplesOf(
      (random) => integerBetween(random, 400, 720).toDouble(),
      runs: 6,
    );

    for (final width in widths) {
      await tester.pumpWidget(
        hostedPlainly(_cardOf(width: width, faceHeights: [232])),
      );

      final card = tester.getRect(find.byType(FlashcardCard));
      final menu = tester.getRect(find.byKey(_menuKey));

      expect(menu.top, card.top + 13);
      expect(menu.right, card.right - 13);
    }
  });

  testWidgets('FlashcardCard property fits faces taller than its room', (
    tester,
  ) async {
    final rooms = examplesOf(
      (random) => integerBetween(random, 120, 400).toDouble(),
      runs: 5,
    );

    for (final room in rooms) {
      await tester.pumpWidget(
        hostedPlainly(
          Center(
            child: SizedBox(
              width: 600,
              height: room,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: _cardOf(width: 600, faceHeights: [300, 300])),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(FlashcardCard)).height, room);
    }
  });

  testWidgets('CardMenu property is two quiet 40px icon buttons 4px apart', (
    tester,
  ) async {
    await tester.pumpWidget(
      hostedPlainly(
        Center(
          child: CardMenu(onMnemonic: () {}, onEdit: () {}, onDelete: () {}),
        ),
      ),
    );

    final buttons = tester
        .widgetList<DesignIconButton>(find.byType(DesignIconButton))
        .toList();
    final mnemonic = tester.getRect(find.byWidget(buttons.first));
    final actions = tester.getRect(find.byWidget(buttons.last));
    final dropdown = tester.widget<DesignDropdown>(find.byType(DesignDropdown));
    final entries = dropdown.entries;

    expect(buttons.map((button) => button.icon), [
      DesignIcons.mnemonic,
      DesignIcons.dots,
    ]);
    expect(buttons.map((button) => button.variant), [
      ButtonVariant.quiet,
      ButtonVariant.quiet,
    ]);
    expect(mnemonic.size, const Size(40, 40));
    expect(actions.size, const Size(40, 40));
    expect(actions.left - mnemonic.right, 4);
    expect(dropdown.placement, DropdownPlacement.belowEnd);
    expect(entries.length, 3);
    expect(entries[1], isA<DropdownSeparator>());

    final edit = entries.first as DropdownAction;
    final delete = entries.last as DropdownAction;

    expect(
      (edit.icon, edit.label, edit.tone),
      (DesignIcons.settings, 'Edit card', DropdownTone.plain),
    );
    expect(
      (delete.icon, delete.label, delete.tone),
      (DesignIcons.trash, 'Delete card', DropdownTone.danger),
    );
  });

  testWidgets('CardMenu property calls the action that was chosen', (
    tester,
  ) async {
    final choices = examplesOf(
      (random) => oneOf(random, ['mnemonic', 'Edit card', 'Delete card']),
      runs: 8,
    );
    final calls = <String>[];

    await tester.pumpWidget(
      hostedPlainly(
        Center(
          child: CardMenu(
            onMnemonic: () => calls.add('mnemonic'),
            onEdit: () => calls.add('Edit card'),
            onDelete: () => calls.add('Delete card'),
          ),
        ),
      ),
    );

    for (final choice in choices) {
      if (choice == 'mnemonic') {
        await tester.tap(find.bySemanticsLabel(_mnemonicLabel));
      } else {
        await tester.tap(find.bySemanticsLabel(_actionsLabel));
        await tester.pumpAndSettle();
        await tester.tap(find.text(choice));
      }

      await tester.pumpAndSettle();
    }

    expect(calls, choices);
    expect(find.text('Edit card'), findsNothing);
  });
}
