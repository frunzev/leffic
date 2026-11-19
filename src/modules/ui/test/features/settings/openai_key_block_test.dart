import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/settings/masked_api_key.dart';
import 'package:leffic/features/settings/openai_key_block.dart';
import 'package:leffic/shared/design/button_look.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_field.dart';
import 'package:leffic/shared/design/design_text_field.dart';
import 'package:leffic/shared/settings/openai_key_store.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const double _blockWidth = 526;

class _KeyChanges {
  _KeyChanges({this.refusal});

  final KeychainError? refusal;
  final List<String> saved = [];
  int removals = 0;

  Future<void> save(String key) async {
    final refused = refusal;

    if (refused != null) {
      throw refused;
    }

    saved.add(key);
  }

  Future<void> remove() async {
    final refused = refusal;

    if (refused != null) {
      throw refused;
    }

    removals++;
  }
}

Future<void> _pumpBlock(
  WidgetTester tester, {
  required String? storedKey,
  required _KeyChanges changes,
}) async {
  await tester.pumpWidget(
    hostedPlainly(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: _blockWidth,
          child: OpenAiKeyBlock(
            key: UniqueKey(),
            storedKey: storedKey,
            onSave: changes.save,
            onRemove: changes.remove,
          ),
        ),
      ),
    ),
  );
}

DesignButton _button(WidgetTester tester, String label) {
  return tester.widget<DesignButton>(find.widgetWithText(DesignButton, label));
}

void main() {
  testWidgets('OpenAiKeyBlock property saves only storable keys', (
    tester,
  ) async {
    for (final key in examplesOf(tokenOf, runs: 4)) {
      final changes = _KeyChanges();

      await _pumpBlock(tester, storedKey: null, changes: changes);
      await tester.enterText(find.byType(TextField), '$key !');
      await tester.tap(find.text('Save key'));
      await tester.pumpAndSettle();

      expect(changes.saved, isEmpty);
      expect(find.byType(FieldError), findsOneWidget);
      expect(find.text('That does not look like an API key.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), ' $key ');
      await tester.tap(find.text('Save key'));
      await tester.pumpAndSettle();

      expect(changes.saved, [key]);
      expect(find.byType(FieldError), findsNothing);
    }
  });

  testWidgets('OpenAiKeyBlock property shows a stored key only masked', (
    tester,
  ) async {
    for (final key in examplesOf(
      (random) => tokenOf(random, minimum: 20, maximum: 60),
      runs: 4,
    )) {
      await _pumpBlock(tester, storedKey: key, changes: _KeyChanges());

      final field = tester.widget<DesignTextField>(
        find.byType(DesignTextField),
      );

      expect(field.controller.text, maskApiKey(key));
      expect(field.editability, TextEditability.readOnly);
      expect(find.text(key), findsNothing);
      expect(find.text('Save key'), findsNothing);
      expect(_button(tester, 'Replace').variant, ButtonVariant.standard);
      expect(_button(tester, 'Remove').variant, ButtonVariant.dangerOutline);
    }
  });

  testWidgets('OpenAiKeyBlock property replaces a stored key', (tester) async {
    for (final (storedKey, pastedKey) in examplesOf(
      (random) => (tokenOf(random, minimum: 20), tokenOf(random)),
      runs: 4,
    )) {
      final changes = _KeyChanges();

      await _pumpBlock(tester, storedKey: storedKey, changes: changes);
      await tester.tap(find.text('Replace'));
      await tester.pump();

      final field = tester.widget<DesignTextField>(
        find.byType(DesignTextField),
      );

      expect(field.editability, TextEditability.editable);
      expect(field.visibility, TextVisibility.obscured);
      expect(field.placeholder, 'Paste your OpenAI key');
      expect(find.text('Remove'), findsNothing);

      await tester.enterText(find.byType(TextField), pastedKey);
      await tester.tap(find.text('Save key'));
      await tester.pumpAndSettle();

      expect(changes.saved, [pastedKey]);
    }
  });

  testWidgets('OpenAiKeyBlock property removes a stored key', (tester) async {
    final changes = _KeyChanges();

    await _pumpBlock(tester, storedKey: 'sk-stored-key-1234', changes: changes);
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(changes.removals, 1);
  });

  testWidgets('OpenAiKeyBlock property explains a keychain refusal', (
    tester,
  ) async {
    for (final (message, storedKey) in examplesOf(
      (random) => (
        'The keychain refused ${wordOf(random)}',
        oneOf(random, [null, 'sk-stored-key-1234']),
      ),
      runs: 6,
    )) {
      final changes = _KeyChanges(refusal: KeychainError(message));

      await _pumpBlock(tester, storedKey: storedKey, changes: changes);

      if (storedKey == null) {
        await tester.enterText(find.byType(TextField), 'sk-valid');
        await tester.tap(find.text('Save key'));
      } else {
        await tester.tap(find.text('Remove'));
      }

      await tester.pumpAndSettle();

      expect(find.text(message), findsOneWidget);
      expect(find.byType(FieldError), findsOneWidget);
    }
  });

  testWidgets('OpenAiKeyBlock property is laid out like .key-block', (
    tester,
  ) async {
    for (final storedKey in [null, 'sk-stored-key-1234']) {
      await _pumpBlock(tester, storedKey: storedKey, changes: _KeyChanges());

      final block = tester.getRect(find.byType(OpenAiKeyBlock));
      final name = tester.getRect(find.text('OpenAI'));
      final nameStyle = renderedStyleOf(tester, 'OpenAI');
      final field = tester.getRect(find.byType(DesignTextField));
      final buttons = find.byType(DesignButton);
      final firstButton = tester.getRect(buttons.first);
      final lastButton = tester.getRect(buttons.last);

      expect(name.top - block.top, 17);
      expect(nameStyle.fontSize, 14);
      expect(nameStyle.fontWeight, FontWeight.w600);
      expect(field.top - name.bottom, 12);
      expect(field.left, block.left);
      expect(field.height, 40);
      expect(firstButton.left - field.right, 12);
      expect(lastButton.right, block.right);
      expect(firstButton.bottom, field.bottom);

      if (storedKey != null) {
        final secondButton = tester.getRect(buttons.at(1));

        expect(secondButton.left - firstButton.right, 12);
      }
    }
  });
}
