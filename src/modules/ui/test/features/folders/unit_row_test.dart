import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/folders/folder_models.dart';
import 'package:leffic/features/folders/unit_badge.dart';
import 'package:leffic/features/folders/unit_presentation.dart';
import 'package:leffic/features/folders/unit_row.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_dropdown.dart';
import 'package:leffic/shared/design/icons/design_icon.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';
import 'folder_fakes.dart';

const double _rowWidth = 640;
const Key _rowBackgroundKey = ValueKey('unit row background');
const BorderRadius _corners = BorderRadius.vertical(top: Radius.circular(14));

class _RowCalls {
  final List<String> calls = [];

  Widget row(FolderUnit unit, String meta, {int dueCount = 0}) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: _rowWidth,
        child: UnitRow(
          unit: unit,
          meta: meta,
          dueCount: dueCount,
          corners: _corners,
          onOpen: () => calls.add('open'),
          menuEntries: [
            DropdownAction(
              icon: DesignIcons.settings,
              label: 'Rename',
              onSelected: () => calls.add('rename'),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _RowExample = ({FolderUnit unit, String meta, Brightness brightness});

List<_RowExample> _rowExamples(int runs) {
  return examplesOf(
    (random) => (
      unit: FolderUnit.fromJson(generatedUnitJson(random, 'unit')),
      meta: 'Meta ${wordOf(random)}',
      brightness: oneOf(random, Brightness.values),
    ),
    runs: runs,
  );
}

Finder _unitIcon() {
  return find
      .descendant(of: find.byType(UnitRow), matching: find.byType(DesignIcon))
      .first;
}

Future<TestGesture> _hoverAt(WidgetTester tester, Offset location) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);

  await mouse.addPointer(location: Offset.zero);
  await mouse.moveTo(location);
  await tester.pump();

  return mouse;
}

BorderRadiusGeometry? _rowCorners(WidgetTester tester) {
  final background = tester.widget<DecoratedBox>(find.byKey(_rowBackgroundKey));

  return (background.decoration as BoxDecoration).borderRadius;
}

Color? _rowFill(WidgetTester tester) {
  final background = tester.widget<DecoratedBox>(find.byKey(_rowBackgroundKey));

  return (background.decoration as BoxDecoration).color;
}

void main() {
  testWidgets('UnitLink property lays out like .unit-link in its row', (
    tester,
  ) async {
    for (final example in _rowExamples(12)) {
      final unit = example.unit;
      final colors = DesignColors.forBrightness(example.brightness);

      await tester.pumpWidget(
        hostedInTheme(
          _RowCalls().row(unit, example.meta),
          brightness: example.brightness,
        ),
      );

      final row = tester.getRect(find.byType(UnitRow));
      final icon = tester.getRect(_unitIcon());
      final name = tester.getRect(find.text(unit.name));
      final meta = tester.getRect(find.text(example.meta));
      final menu = tester.getRect(find.byType(DesignIconButton));
      final nameStyle = renderedStyleOf(tester, unit.name);
      final metaStyle = renderedStyleOf(tester, example.meta);
      final iconWidget = tester.widget<DesignIcon>(_unitIcon());

      expect(row.height, 52);
      expect(icon.left - row.left, 16);
      expect(icon.size, const Size.square(20));
      expect(icon.center.dy, closeTo(row.center.dy, 0.01));
      expect(iconWidget.icon, iconForUnitType(unit.type));
      expect(iconWidget.color, colors.inkTertiary);
      expect(name.left - icon.right, 12);
      expect(meta.left, name.left);
      expect(meta.top, closeTo(name.bottom, 0.01));
      expect(nameStyle.fontSize, 16);
      expect(nameStyle.color, colors.ink);
      expect(metaStyle.fontSize, 12);
      expect(metaStyle.color, colors.inkTertiary);
      expect(menu.size, const Size.square(40));
      expect(row.right - menu.right, 8);
      expect(menu.center.dy, closeTo(row.center.dy, 0.01));
    }
  });

  testWidgets('UnitRow property keeps a long name on one ellipsized line', (
    tester,
  ) async {
    for (final example in _rowExamples(4)) {
      final longName = List.filled(30, example.unit.name).join(' ');
      final unit = FolderUnit(
        id: example.unit.id,
        name: longName,
        type: example.unit.type,
        createdAt: example.unit.createdAt,
        extension: example.unit.extension,
        details: example.unit.details,
      );

      await tester.pumpWidget(
        hostedInLightTheme(_RowCalls().row(unit, example.meta)),
      );

      final nameText = tester.widget<Text>(find.text(longName));
      final name = tester.getRect(find.text(longName));
      final menu = tester.getRect(find.byType(DesignIconButton));

      expect(nameText.maxLines, 1);
      expect(nameText.overflow, TextOverflow.ellipsis);
      expect(menu.left - name.right, greaterThanOrEqualTo(8));
      expect(tester.getSize(find.byType(UnitRow)).height, 52);
    }
  });

  testWidgets('UnitRow property fills the row and underlines on hover', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final example in _rowExamples(4)) {
      final unit = example.unit;

      await tester.pumpWidget(
        hostedInLightTheme(_RowCalls().row(unit, example.meta)),
      );

      expect(_rowFill(tester), isNot(colors.hover));
      expect(
        renderedStyleOf(tester, unit.name).decoration,
        isNot(TextDecoration.underline),
      );

      final mouse = await _hoverAt(
        tester,
        tester.getCenter(find.text(unit.name)),
      );

      expect(_rowFill(tester), colors.hover);
      expect(
        renderedStyleOf(tester, unit.name).decoration,
        TextDecoration.underline,
      );

      await mouse.moveTo(tester.getCenter(find.byType(DesignIconButton)));
      await tester.pump();

      expect(_rowFill(tester), colors.hover);
      expect(
        renderedStyleOf(tester, unit.name).decoration,
        isNot(TextDecoration.underline),
      );
      expect(_rowCorners(tester), _corners);

      await mouse.removePointer();
    }
  });

  testWidgets('UnitRow property shows a .unit-badge only when work is due', (
    tester,
  ) async {
    for (final example in examplesOf(
      (random) => (
        unit: FolderUnit.fromJson(generatedUnitJson(random, 'unit')),
        dueCount: oneOf(random, [0, integerBetween(random, 1, 400)]),
      ),
      runs: 10,
    )) {
      final unit = example.unit;
      final badgeLabel = dueBadgeLabel(example.dueCount);

      await tester.pumpWidget(
        hostedInLightTheme(
          _RowCalls().row(unit, 'Meta', dueCount: example.dueCount),
        ),
      );

      if (example.dueCount == 0) {
        expect(find.byType(UnitBadge), findsNothing);
        continue;
      }

      final row = tester.getRect(find.byType(UnitRow));
      final badge = tester.getRect(find.byType(UnitBadge));
      final menu = tester.getRect(find.byType(DesignIconButton));
      final name = tester.getRect(find.text(unit.name));

      expect(find.text(badgeLabel), findsOneWidget);
      expect(menu.left - badge.right, 8);
      expect(badge.left - name.right, greaterThanOrEqualTo(12));
      expect(badge.center.dy, closeTo(row.center.dy, 0.01));
      expect(row.height, 52);
    }
  });

  testWidgets('UnitRow property opens the unit and its menu', (tester) async {
    for (final example in _rowExamples(4)) {
      final unit = example.unit;
      final recorder = _RowCalls();

      await tester.pumpWidget(
        hostedInLightTheme(recorder.row(unit, example.meta)),
      );
      await tester.tap(find.text(unit.name));
      await tester.tap(find.bySemanticsLabel('More actions for ${unit.name}'));
      await tester.pumpAndSettle();

      final row = tester.getRect(find.byType(UnitRow));
      final panel = tester.getRect(find.byType(DropdownPanel));

      expect(panel.top, closeTo(row.bottom - 4, 0.01));
      expect(panel.right, closeTo(row.right - 8, 0.01));

      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(recorder.calls, ['open', 'rename']);
      expect(find.byType(DropdownPanel), findsNothing);
    }
  });
}
