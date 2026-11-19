import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_divider.dart';
import 'package:leffic/shared/design/design_dropdown.dart';
import 'package:leffic/shared/design/icons/design_icon.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const Key _anchorKey = Key('dropdown anchor');
const Size _anchorSize = Size(120, 40);

class _Menu {
  final List<String> chosen = [];

  Widget buildAnchor(BuildContext context, OverlayPortalController menu) {
    return GestureDetector(
      onTap: menu.toggle,
      child: const ColoredBox(
        color: Color(0xFF888888),
        child: SizedBox(
          key: _anchorKey,
          width: 120,
          height: 40,
          child: Text('Open'),
        ),
      ),
    );
  }

  List<DropdownEntry> entries() {
    return [
      DropdownAction(
        icon: DesignIcons.study,
        label: 'Review now',
        hint: '12 due',
        onSelected: () => chosen.add('review'),
      ),
      const DropdownSeparator(),
      DropdownAction(
        icon: DesignIcons.trash,
        label: 'Delete deck',
        tone: DropdownTone.danger,
        onSelected: () => chosen.add('delete'),
      ),
    ];
  }
}

Future<_Menu> _pumpOpen(
  WidgetTester tester,
  DropdownPlacement placement,
) async {
  final menu = _Menu();

  await tester.pumpWidget(
    hostedPlainly(
      Center(
        child: DesignDropdown(
          placement: placement,
          entries: menu.entries(),
          anchorBuilder: menu.buildAnchor,
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(_anchorKey));
  await tester.pumpAndSettle();

  return menu;
}

void main() {
  testWidgets('DesignDropdown property places the menu where CSS puts it', (
    tester,
  ) async {
    for (final placement in [
      DropdownPlacement.belowStart,
      DropdownPlacement.belowEnd,
      DropdownPlacement.besideEnd,
      const DropdownPlacement(
        targetAnchor: Alignment.bottomRight,
        followerAnchor: Alignment.topRight,
        offset: Offset(-8, -4),
      ),
    ]) {
      await _pumpOpen(tester, placement);

      final anchor = tester.getRect(find.byKey(_anchorKey));
      final panel = tester.getRect(find.byType(DropdownPanel));
      final target = placement.targetAnchor.withinRect(anchor);
      final follower = placement.followerAnchor.withinRect(panel);

      expect(follower - target, placement.offset);
      expect(anchor.size, _anchorSize);
    }
  });

  testWidgets('DesignDropdown property keeps the CSS offsets of each menu', (
    tester,
  ) async {
    expect(DropdownPlacement.belowStart.offset, const Offset(0, 8));
    expect(DropdownPlacement.belowStart.targetAnchor, Alignment.bottomLeft);
    expect(DropdownPlacement.belowStart.followerAnchor, Alignment.topLeft);
    expect(DropdownPlacement.belowEnd.offset, const Offset(0, 8));
    expect(DropdownPlacement.belowEnd.targetAnchor, Alignment.bottomRight);
    expect(DropdownPlacement.belowEnd.followerAnchor, Alignment.topRight);
    expect(DropdownPlacement.besideEnd.offset, const Offset(8, 0));
    expect(DropdownPlacement.besideEnd.targetAnchor, Alignment.bottomRight);
    expect(DropdownPlacement.besideEnd.followerAnchor, Alignment.bottomLeft);
  });

  testWidgets('DropdownPanel property sizes items like .dropdown-item', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    await _pumpOpen(tester, DropdownPlacement.belowStart);

    final panel = tester.getRect(find.byType(DropdownPanel));
    final items = tester.widgetList(find.byType(DropdownItem)).toList();
    final reviewItem = tester.getRect(find.byType(DropdownItem).first);
    final icon = tester.getRect(find.byType(DesignIcon).first);
    final label = tester.getRect(find.text('Review now'));
    final hint = tester.getRect(find.text('12 due'));
    final divider = tester.getRect(find.byType(DesignDivider));
    final opacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.byType(DesignIcon).first,
        matching: find.byType(Opacity),
      ),
    );

    expect(items, hasLength(2));
    expect(panel.width, greaterThanOrEqualTo(208));
    expect(reviewItem.left - panel.left, 5);
    expect(reviewItem.top - panel.top, 5);
    expect(panel.right - reviewItem.right, 5);
    expect(reviewItem.height, 40);
    expect(icon.size, const Size.square(18));
    expect(icon.left - reviewItem.left, 8);
    expect(label.left - icon.right, 12);
    expect(reviewItem.right - hint.right, 8);
    expect(divider.height, 1);
    expect(divider.top, reviewItem.bottom);
    expect(opacity.opacity, 0.7);
    expect(renderedStyleOf(tester, 'Review now').fontSize, 14);
    expect(renderedStyleOf(tester, 'Review now').color, colors.ink);
    expect(renderedStyleOf(tester, '12 due').fontSize, 12);
    expect(renderedStyleOf(tester, '12 due').color, colors.inkTertiary);
    expect(renderedStyleOf(tester, 'Delete deck').color, colors.danger);
  });

  testWidgets('DesignDropdown property closes and acts on a choice', (
    tester,
  ) async {
    for (final label in examplesOf(
      (random) => oneOf(random, ['Review now', 'Delete deck']),
      runs: 4,
    )) {
      final menu = await _pumpOpen(tester, DropdownPlacement.belowEnd);

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(find.byType(DropdownPanel), findsNothing);
      expect(menu.chosen, [label == 'Review now' ? 'review' : 'delete']);
    }
  });

  testWidgets('DesignDropdown property closes on an outside tap or Escape', (
    tester,
  ) async {
    await _pumpOpen(tester, DropdownPlacement.belowEnd);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(find.byType(DropdownPanel), findsNothing);

    await tester.tap(find.byKey(_anchorKey));
    await tester.pumpAndSettle();

    expect(find.byType(DropdownPanel), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(DropdownPanel), findsNothing);
  });

  testWidgets('DesignDropdown property toggles from its anchor', (
    tester,
  ) async {
    await _pumpOpen(tester, DropdownPlacement.belowEnd);
    await tester.tap(find.byKey(_anchorKey));
    await tester.pumpAndSettle();

    expect(find.byType(DropdownPanel), findsNothing);
  });
}
