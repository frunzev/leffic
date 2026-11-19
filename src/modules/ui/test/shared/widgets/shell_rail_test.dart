import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/dropdown_parts.dart';
import 'package:leffic/shared/design/icons/design_icon.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';
import 'package:leffic/shared/navigation/routes.dart';
import 'package:leffic/shared/widgets/rail_item.dart';

import '../../support/rendered_text.dart';
import 'shell_harness.dart';

void main() {
  testWidgets('AppShell property lays out the rail like app-rail.css', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    await pumpShell(tester, Routes.folder);

    final logo = tester.getRect(
      find.byWidgetPredicate(
        (widget) => widget is DesignIcon && widget.icon == DesignIcons.logo,
      ),
    );
    final home = tester.getRect(find.byType(RailItem).at(0));
    final ask = tester.getRect(find.byType(RailItem).at(1));
    final profile = tester.getRect(find.byType(RailItem).at(2));
    final homeIcon = tester.getRect(
      find.descendant(
        of: find.byType(RailItem).at(0),
        matching: find.byType(DesignIcon),
      ),
    );
    final homeLabel = tester.getRect(find.text('Home'));
    final labelStyle = renderedStyleOf(tester, 'Ask');

    expect(logo, const Rect.fromLTWH(19.5, 12, 32, 32));
    expect(home.top - logo.bottom, 16);
    expect(home.left, 8);
    expect(home.width, 55);
    expect(ask.top - home.bottom, 4);
    expect(homeIcon.top - home.top, 8);
    expect(homeIcon.size, const Size.square(20));
    expect(homeLabel.top - homeIcon.bottom, 4);
    expect(home.bottom - homeLabel.bottom, 8);
    expect(profile.bottom, 900 - 12);
    expect(labelStyle.fontSize, 12);
    expect(labelStyle.fontWeight, FontWeight.w500);
    expect(labelStyle.color, colors.inkSecondary);
    expect(renderedStyleOf(tester, 'Home').color, colors.brandStrong);
  });

  testWidgets('AppShell property offers only Settings in the Profile menu', (
    tester,
  ) async {
    final harness = await pumpShell(tester, Routes.folder);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    final items = tester.widgetList<DropdownItem>(find.byType(DropdownItem));
    final menu = tester.getRect(find.byType(DropdownPanel));
    final profile = tester.getRect(find.byType(RailItem).at(2));

    expect(items.map((item) => item.label), ['Settings']);
    expect(items.single.icon, DesignIcons.settings);
    expect(find.text('Log out'), findsNothing);
    expect(menu.left, profile.right + 8);
    expect(menu.bottom, profile.bottom);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(harness.opened.last, Routes.settings);
    expect(find.byType(DropdownPanel), findsNothing);
  });

  testWidgets('RailItem property follows hover and current colours', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    await pumpShell(tester, Routes.note);

    final idleHome = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(RailItem).at(0),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );

    expect(
      (idleHome.decoration as BoxDecoration).color,
      const Color(0x00000000),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);

    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('Home')));
    await tester.pump();

    final hoveredHome = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(RailItem).at(0),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );

    expect((hoveredHome.decoration as BoxDecoration).color, colors.hover);
    expect(renderedStyleOf(tester, 'Home').color, colors.ink);

    await mouse.removePointer();
  });
}
