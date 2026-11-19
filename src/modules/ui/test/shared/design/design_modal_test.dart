import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_modal.dart';
import 'package:leffic/shared/design/design_overlay.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const Key _bodyKey = Key('modal body');
const Key _firstActionKey = Key('first action');
const Key _lastActionKey = Key('last action');
const Key _openerKey = Key('opener');

Widget _sampleModal(ModalWidth width) {
  return DesignModal(
    title: 'Create a folder',
    description: 'Folders keep related study units together.',
    width: width,
    body: const SizedBox(key: _bodyKey, height: 66),
    actions: const [
      SizedBox(key: _firstActionKey, width: 80, height: 40),
      SizedBox(key: _lastActionKey, width: 90, height: 40),
    ],
  );
}

class _ModalOpener {
  _ModalOpener(this.width);

  final ModalWidth width;
  final List<Object?> results = [];

  Widget buildModal(BuildContext context) => _sampleModal(width);

  void open(BuildContext context) {
    unawaited(
      showDesignModal<Object?>(
        context: context,
        builder: buildModal,
      ).then(results.add),
    );
  }

  Widget buildOpener(BuildContext context) {
    return Center(
      child: TextButton(
        key: _openerKey,
        onPressed: () => open(context),
        child: const Text('open'),
      ),
    );
  }
}

Future<_ModalOpener> _openModal(
  WidgetTester tester,
  Size surface,
  ModalWidth width,
) async {
  final opener = _ModalOpener(width);

  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(hostedPlainly(Builder(builder: opener.buildOpener)));
  await tester.tap(find.byKey(_openerKey));
  await tester.pumpAndSettle();

  return opener;
}

void main() {
  testWidgets('DesignModal property is as wide as the CSS allows, centred', (
    tester,
  ) async {
    for (final (surfaceWidth, width) in examplesOf(
      (random) => (
        integerBetween(random, 360, 1440).toDouble(),
        oneOf(random, ModalWidth.values),
      ),
      runs: 10,
    )) {
      await _openModal(tester, Size(surfaceWidth, 900), width);

      final modal = tester.getRect(find.byType(DesignModal));
      final cssMaximum = width == ModalWidth.wide ? 600.0 : 420.0;

      expect(modal.width, min(cssMaximum, surfaceWidth - 32));
      expect(modal.center.dx, closeTo(surfaceWidth / 2, 1e-6));
      expect(modal.center.dy, closeTo(450, 1e-6));
    }
  });

  testWidgets('DesignModal property pads head, body and foot like the CSS', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    await _openModal(tester, const Size(1440, 900), ModalWidth.regular);

    final modal = tester.getRect(find.byType(DesignModal));
    final title = tester.getRect(find.text('Create a folder'));
    final description = tester.getRect(
      find.text('Folders keep related study units together.'),
    );
    final close = tester.getRect(find.byType(DesignIconButton));
    final body = tester.getRect(find.byKey(_bodyKey));
    final firstAction = tester.getRect(find.byKey(_firstActionKey));
    final lastAction = tester.getRect(find.byKey(_lastActionKey));
    final titleStyle = renderedStyleOf(tester, 'Create a folder');
    final descriptionStyle = renderedStyleOf(
      tester,
      'Folders keep related study units together.',
    );

    expect(title.left - modal.left, 25);
    expect(title.top - modal.top, 21);
    expect(description.top - title.bottom, 2);
    expect(close.top - modal.top, 17);
    expect(modal.right - close.right, 17);
    expect(close.left - title.right, greaterThanOrEqualTo(12));
    expect(body.left - modal.left, 25);
    expect(modal.right - body.right, 25);
    expect(body.top - max(description.bottom, close.bottom), 16);
    expect(firstAction.top - body.bottom, 8 + 12);
    expect(lastAction.left - firstAction.right, 8);
    expect(modal.right - lastAction.right, 25);
    expect(modal.bottom - lastAction.bottom, 25);
    expect(titleStyle.fontSize, 16);
    expect(titleStyle.fontWeight, FontWeight.w600);
    expect(titleStyle.letterSpacing, closeTo(-0.31 - 0.16, 1e-9));
    expect(descriptionStyle.fontSize, 14);
    expect(descriptionStyle.color, colors.inkSecondary);
  });

  testWidgets('showDesignModal property dims and blurs behind the modal', (
    tester,
  ) async {
    await _openModal(tester, const Size(1440, 900), ModalWidth.regular);

    final barrier = tester.widget<ModalBarrier>(find.byType(ModalBarrier).last);
    final blur = tester.widget<BackdropFilter>(find.byType(BackdropFilter));

    expect(barrier.color, DesignColors.forBrightness(Brightness.light).scrim);
    expect(blur.filter, ImageFilter.blur(sigmaX: 3, sigmaY: 3));
  });

  testWidgets('showDesignModal property closes from the close button', (
    tester,
  ) async {
    final opener = await _openModal(
      tester,
      const Size(1440, 900),
      ModalWidth.wide,
    );

    await tester.tap(find.bySemanticsLabel('Close dialog'));
    await tester.pumpAndSettle();

    expect(find.byType(DesignModal), findsNothing);
    expect(opener.results, [null]);
  });

  testWidgets('showDesignModal property closes when the scrim is tapped', (
    tester,
  ) async {
    await _openModal(tester, const Size(1440, 900), ModalWidth.regular);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.byType(DesignModal), findsNothing);
  });

  testWidgets('DesignOverlay property has the 52px overlay bar', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final title in examplesOf((random) => 'Review ${wordOf(random)}')) {
      var closes = 0;

      await tester.pumpWidget(
        hostedPlainly(
          DesignOverlay(
            title: title,
            closeLabel: 'End review',
            onClose: () => closes++,
            child: const SizedBox.expand(key: _bodyKey),
          ),
        ),
      );

      final overlay = tester.getRect(find.byType(DesignOverlay));
      final titleBox = tester.getRect(find.text(title));
      final close = tester.getRect(find.byType(DesignIconButton));
      final content = tester.getRect(find.byKey(_bodyKey));
      final titleStyle = renderedStyleOf(tester, title);

      expect(content.top - overlay.top, 52);
      expect(titleBox.left - overlay.left, 16);
      expect(overlay.right - close.right, 12);
      expect(close.center.dy - overlay.top, closeTo(25.5, 1e-6));
      expect(titleStyle.fontSize, 14);
      expect(titleStyle.fontWeight, FontWeight.w600);
      expect(
        tester
            .widget<ColoredBox>(
              find
                  .descendant(
                    of: find.byType(DesignOverlay),
                    matching: find.byType(ColoredBox),
                  )
                  .first,
            )
            .color,
        colors.surfaceSecondary,
      );

      await tester.tap(find.bySemanticsLabel('End review'));

      expect(closes, 1);
    }
  });
}
