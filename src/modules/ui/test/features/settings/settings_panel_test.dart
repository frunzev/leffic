import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/settings/settings_panel.dart';
import 'package:leffic/shared/design/surface_box.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';

const Key _bodyKey = Key('panel body');

void main() {
  testWidgets('SettingsPanel property heads its body with title and text', (
    tester,
  ) async {
    for (final (title, text) in examplesOf(
      (random) => ('Title ${wordOf(random)}', 'Text ${wordOf(random)}'),
      runs: 5,
    )) {
      await tester.pumpWidget(
        hostedPlainly(
          SettingsPanel(
            title: title,
            text: text,
            body: const SizedBox(key: _bodyKey, height: 40),
          ),
        ),
      );

      final titleBox = tester.getRect(find.text(title));
      final textBox = tester.getRect(find.text(text));
      final bodyBox = tester.getRect(find.byKey(_bodyKey));

      expect(titleBox.bottom, lessThanOrEqualTo(textBox.top));
      expect(textBox.bottom, lessThan(bodyBox.top));
      expect(
        find.ancestor(
          of: find.byKey(_bodyKey),
          matching: find.byType(SurfaceBox),
        ),
        findsOneWidget,
      );
    }
  });
}
