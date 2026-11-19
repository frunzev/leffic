import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/widgets/ask_panel_scope.dart';

import '../../support/property.dart';

enum _PanelCommand { open, close, toggle }

void main() {
  test('AskPanelController property ends where the commands lead', () {
    forAll(
      (random) => [
        for (var index = 0; index < integerBetween(random, 0, 12); index++)
          oneOf(random, _PanelCommand.values),
      ],
      (commands) {
        final controller = AskPanelController();
        var expectedOpen = false;
        var notifications = 0;
        var expectedNotifications = 0;

        controller.addListener(() => notifications++);

        for (final command in commands) {
          final wasOpen = expectedOpen;

          switch (command) {
            case _PanelCommand.open:
              controller.open();
              expectedOpen = true;
            case _PanelCommand.close:
              controller.close();
              expectedOpen = false;
            case _PanelCommand.toggle:
              controller.toggle();
              expectedOpen = !expectedOpen;
          }

          if (wasOpen != expectedOpen) {
            expectedNotifications++;
          }
        }

        expect(controller.isOpen, expectedOpen);
        expect(notifications, expectedNotifications);
        controller.dispose();
      },
    );
  });

  testWidgets('AskPanelScope property hands its controller and panel down', (
    tester,
  ) async {
    final controller = AskPanelController();
    late AskPanelScope seen;
    const panel = Text('panel');

    await tester.pumpWidget(
      AskPanelScope(
        controller: controller,
        panel: panel,
        child: Builder(
          builder: (context) {
            seen = AskPanelScope.of(context);

            return const SizedBox();
          },
        ),
      ),
    );

    expect(seen.controller, same(controller));
    expect(seen.panel, same(panel));
    controller.dispose();
  });

  testWidgets('AskPanelScope property fails fast without a scope', (
    tester,
  ) async {
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          AskPanelScope.of(context);

          return const SizedBox();
        },
      ),
    );

    expect(tester.takeException(), isA<FlutterError>());
  });
}
