import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/folders/folder_header.dart';
import 'package:leffic/features/folders/folder_models.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/navigation/routes.dart';

import '../../support/backend_fakes.dart';
import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';
import 'folder_ancestry.dart';

void main() {
  testWidgets('FolderCrumbs property opens Home and lights up on hover', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final name in examplesOf(
      (random) => 'In ${wordOf(random)}',
      runs: 4,
    )) {
      final opened = <RouteSettings>[];

      await tester.pumpWidget(
        KeyedSubtree(
          key: UniqueKey(),
          child: hostedWithBackend(
            client: FakeBackend({}).client(),
            opened: opened,
            child: Scaffold(
              body: FolderCrumbs(
                ancestors: const [rootAncestor],
                folderName: name,
              ),
            ),
          ),
        ),
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);

      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text(crumbHome)));
      await tester.pump();

      final hovered = renderedStyleOf(tester, crumbHome);

      expect(hovered.color, colors.ink);
      expect(hovered.decoration, TextDecoration.underline);

      await tester.tap(find.text(crumbHome));
      await tester.pumpAndSettle();
      await mouse.removePointer();

      expect(opened.single.name, Routes.folder);
      expect((opened.single.arguments! as UnitArguments).id, homeFolderId);
    }
  });

  testWidgets('FolderCrumbs property wraps a trail wider than its column', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final depth in examplesOf(
      (random) => integerBetween(random, 4, 9),
      runs: 4,
    )) {
      final ancestors = [
        rootAncestor,
        for (var level = 1; level < depth; level++)
          FolderAncestor(id: 'deep-$level', name: 'Deep level number $level'),
      ];

      await tester.pumpWidget(
        hostedInLightTheme(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 480,
              child: FolderCrumbs(ancestors: ancestors, folderName: 'Here'),
            ),
          ),
        ),
      );

      final crumbs = tester.getRect(find.byType(FolderCrumbs));

      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.text('Here')).right, lessThanOrEqualTo(480));
      expect(crumbs.width, lessThanOrEqualTo(480));
    }
  });

  testWidgets('FolderCrumbs property opens each ancestor by its id', (
    tester,
  ) async {
    useDesktopSurface(tester);

    for (final ancestors in examplesOf(
      (random) => [rootAncestor, ...generatedAncestors(random).skip(1)],
      runs: 6,
    )) {
      final opened = <RouteSettings>[];

      await tester.pumpWidget(
        KeyedSubtree(
          key: UniqueKey(),
          child: hostedWithBackend(
            client: FakeBackend({}).client(),
            opened: opened,
            child: Scaffold(
              body: FolderCrumbs(ancestors: ancestors, folderName: 'Here'),
            ),
          ),
        ),
      );

      for (final ancestor in ancestors.skip(1)) {
        await tester.tap(find.text(ancestor.name));
        await tester.pumpAndSettle();

        final arguments = opened.last.arguments! as UnitArguments;

        expect(opened.last.name, Routes.folder);
        expect(arguments.id, ancestor.id);
        expect(arguments.name, ancestor.name);

        tester.state<NavigatorState>(find.byType(Navigator).last).pop();
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('CrumbLink property is a quiet link that lights up on hover', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final label in examplesOf(
      (random) => 'Crumb ${wordOf(random)}',
      runs: 4,
    )) {
      var presses = 0;

      await tester.pumpWidget(
        hostedInLightTheme(
          Center(
            child: CrumbLink(label: label, onPressed: () => presses++),
          ),
        ),
      );

      expect(renderedStyleOf(tester, label).color, colors.inkTertiary);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);

      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text(label)));
      await tester.pump();

      expect(renderedStyleOf(tester, label).color, colors.ink);
      expect(
        renderedStyleOf(tester, label).decoration,
        TextDecoration.underline,
      );

      await tester.tap(find.text(label));
      await mouse.removePointer();

      expect(presses, 1);
    }
  });
}
