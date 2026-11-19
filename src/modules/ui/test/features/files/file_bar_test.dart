import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/files/file_bar.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/icons/design_icon.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const Key _detailKey = Key('detail');
const Key _toolKey = Key('tool');
const Key _actionKey = Key('action');
const Key _barKey = Key('bar');

Widget _barWithActionsIn(double width, String fileName) {
  return hostedInLightTheme(
    Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        child: FileBar(
          key: _barKey,
          fileName: fileName,
          details: const [SizedBox(key: _detailKey, width: 40, height: 20)],
          tools: const [SizedBox(key: _toolKey, width: 80, height: 36)],
          actions: const [SizedBox(key: _actionKey, width: 160, height: 36)],
        ),
      ),
    ),
  );
}

Widget _barHostedIn(Brightness brightness, double width, String fileName) {
  return hostedInTheme(
    Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        child: FileBar(
          key: _barKey,
          fileName: fileName,
          details: const [SizedBox(key: _detailKey, width: 40, height: 20)],
          tools: const [SizedBox(key: _toolKey, width: 40, height: 40)],
        ),
      ),
    ),
    brightness: brightness,
  );
}

void _useWideSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('FileBar property lays out the file bar of the CSS', (
    tester,
  ) async {
    for (final (width, fileName, brightness) in examplesOf(
      (random) => (
        integerBetween(random, 600, 1400).toDouble(),
        '${wordOf(random)}.pdf',
        oneOf(random, Brightness.values),
      ),
      runs: 10,
    )) {
      _useWideSurface(tester);
      final colors = DesignColors.forBrightness(brightness);

      await tester.pumpWidget(_barHostedIn(brightness, width, fileName));

      final barBox = tester.getRect(find.byKey(_barKey));
      final iconBox = tester.getRect(find.byType(DesignIcon));
      final nameBox = tester.getRect(find.text(fileName));
      final detailBox = tester.getRect(find.byKey(_detailKey));
      final toolBox = tester.getRect(find.byKey(_toolKey));
      final icon = tester.widget<DesignIcon>(find.byType(DesignIcon));
      final name = renderedStyleOf(tester, fileName);

      expect(barBox.height, 52);
      expect(iconBox.left, 16);
      expect(iconBox.top, 15.5);
      expect(icon.icon, DesignIcons.file);
      expect(icon.color, colors.inkTertiary);
      expect(nameBox.left - iconBox.right, 12);
      expect(detailBox.left - nameBox.right, 12);
      expect(toolBox.right, width - 16);
      expect(toolBox.top, 5.5);
      expect(name.fontSize, 14);
      expect(name.fontWeight, FontWeight.w500);
    }
  });

  testWidgets('FileBar property shortens a long name instead of overflowing', (
    tester,
  ) async {
    for (final repeats in examplesOf(
      (random) => integerBetween(random, 20, 60),
      runs: 4,
    )) {
      final fileName = '${'long' * repeats}.pdf';

      await tester.pumpWidget(_barHostedIn(Brightness.light, 600, fileName));

      final nameBox = tester.getRect(find.text(fileName));
      final detailBox = tester.getRect(find.byKey(_detailKey));
      final toolBox = tester.getRect(find.byKey(_toolKey));

      expect(tester.takeException(), isNull);
      expect(detailBox.left - nameBox.right, 12);
      expect(toolBox.left - detailBox.right, 12);
    }
  });

  testWidgets('FileBar property centres the tools between the two ends', (
    tester,
  ) async {
    for (final (width, fileName) in examplesOf(
      (random) => (
        integerBetween(random, 700, 1400).toDouble(),
        '${wordOf(random)}.pdf',
      ),
      runs: 8,
    )) {
      _useWideSurface(tester);

      await tester.pumpWidget(_barWithActionsIn(width, fileName));

      final detailBox = tester.getRect(find.byKey(_detailKey));
      final toolBox = tester.getRect(find.byKey(_toolKey));
      final actionBox = tester.getRect(find.byKey(_actionKey));
      final gapBeforeTools = toolBox.left - detailBox.right;
      final gapAfterTools = actionBox.left - toolBox.right;

      expect(actionBox.right, width - 16);
      expect(gapBeforeTools, moreOrLessEquals(gapAfterTools));
      expect(gapBeforeTools, greaterThanOrEqualTo(12));
      expect(actionBox.top, 7.5);
    }
  });

  testWidgets('FileBar property shortens a long name beside its actions', (
    tester,
  ) async {
    for (final repeats in examplesOf(
      (random) => integerBetween(random, 30, 60),
      runs: 4,
    )) {
      final fileName = '${'long' * repeats}.pdf';

      await tester.pumpWidget(_barWithActionsIn(700, fileName));

      final detailBox = tester.getRect(find.byKey(_detailKey));
      final toolBox = tester.getRect(find.byKey(_toolKey));
      final actionBox = tester.getRect(find.byKey(_actionKey));

      expect(tester.takeException(), isNull);
      expect(toolBox.left - detailBox.right, 12);
      expect(actionBox.left - toolBox.right, 12);
      expect(actionBox.right, 700 - 16);
    }
  });
}
