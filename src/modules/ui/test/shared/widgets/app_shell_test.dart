import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/navigation/routes.dart';
import 'package:leffic/shared/widgets/app_shell.dart';
import 'package:leffic/shared/widgets/ask_panel_scope.dart';
import 'package:leffic/shared/widgets/shell_rail.dart';

import '../../support/property.dart';
import 'shell_harness.dart';

void main() {
  testWidgets('AppShell property draws the 72px rail beside the page', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final route in examplesOf((random) => oneOf(random, shellRoutes))) {
      await pumpShell(tester, route);

      final body = tester.getRect(find.byKey(shellBodyKey));
      final rail = tester.getRect(find.byType(ShellRail));
      final railBox = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(ShellRail),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = railBox.decoration as BoxDecoration;

      expect(rail, const Rect.fromLTWH(0, 0, 72, 900));
      expect(body.left, 72);
      expect(body.width, 1440 - 72);
      expect(decoration.color, colors.surfaceSecondary);
      expect(decoration.border, Border(right: BorderSide(color: colors.line)));
    }
  });

  testWidgets('AppShell property marks Home current only on folder pages', (
    tester,
  ) async {
    for (final route in examplesOf((random) => oneOf(random, shellRoutes))) {
      await pumpShell(tester, route);

      expect(
        railItemLabelled(tester, 'Home').isCurrent,
        route == Routes.folder,
      );
      expect(railItemLabelled(tester, 'Ask').isCurrent, isFalse);
      expect(railItemLabelled(tester, 'Profile').isCurrent, isFalse);
    }
  });

  testWidgets('AppShell property opens the Ask panel beside the rail', (
    tester,
  ) async {
    for (final (route, width) in examplesOf(
      (random) => (
        oneOf(random, shellRoutes),
        integerBetween(random, 420, 1440).toDouble(),
      ),
      runs: 8,
    )) {
      final harness = await pumpShell(tester, route, surface: Size(width, 900));

      expect(find.byKey(askPanelKey), findsNothing);

      await tester.tap(find.text('Ask'));
      await tester.pumpAndSettle();

      final panel = tester.getRect(find.byKey(askPanelKey));

      expect(harness.askPanel.isOpen, isTrue);
      expect(panel, Rect.fromLTWH(72, 0, min(380, width - 72), 900));
      expect(railItemLabelled(tester, 'Ask').isCurrent, isTrue);
      expect(railItemLabelled(tester, 'Home').isCurrent, isFalse);

      await tester.tap(find.text('Ask'));
      await tester.pumpAndSettle();

      expect(find.byKey(askPanelKey), findsNothing);
      expect(harness.askPanel.isOpen, isFalse);
    }
  });

  testWidgets('AppShell property opens Home even from inside a folder', (
    tester,
  ) async {
    final harness = await pumpShell(tester, Routes.folder);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(harness.opened.where((name) => name == Routes.folder), isNotEmpty);
  });

  testWidgets('AppShell property keeps the rail full height for any page', (
    tester,
  ) async {
    for (final contentHeight in examplesOf(
      (random) => integerBetween(random, 0, 1200).toDouble(),
      runs: 6,
    )) {
      final askPanel = AskPanelController();

      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        AskPanelScope(
          controller: askPanel,
          panel: const SizedBox.shrink(),
          child: MaterialApp(
            key: UniqueKey(),
            home: AppShell(
              selectedRoute: Routes.settings,
              body: SingleChildScrollView(
                child: SizedBox(key: shellBodyKey, height: contentHeight),
              ),
            ),
          ),
        ),
      );

      final rail = tester.getRect(find.byType(ShellRail));
      final page = tester.getRect(find.byType(SingleChildScrollView));

      expect(rail, const Rect.fromLTWH(0, 0, 72, 900));
      expect(page, const Rect.fromLTWH(72, 0, 1440 - 72, 900));
      askPanel.dispose();
    }
  });
}
