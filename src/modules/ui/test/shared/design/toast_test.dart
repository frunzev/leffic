import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/icons/design_icon.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';
import 'package:leffic/shared/design/toast.dart';
import 'package:leffic/shared/design/toast_host.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const Map<ToastTone, DesignIcons> _cssIcons = {
  ToastTone.progress: DesignIcons.start,
  ToastTone.success: DesignIcons.success,
  ToastTone.failure: DesignIcons.failure,
};

Color _cssTone(ToastTone tone, DesignColors colors) {
  return switch (tone) {
    ToastTone.progress => colors.brand,
    ToastTone.success => colors.success,
    ToastTone.failure => colors.danger,
  };
}

Widget _toastIn(Widget toast, {required bool disableAnimations}) {
  return hostedPlainly(
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Center(child: SizedBox(width: 360, child: toast)),
    ),
  );
}

void main() {
  testWidgets('Toast property lays out like .toast with its tone', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final (tone, title, detail) in examplesOf(
      (random) => (
        oneOf(random, ToastTone.values),
        'Title ${wordOf(random)}',
        oneOf(random, [null, 'Detail ${wordOf(random)}']),
      ),
      runs: 10,
    )) {
      var dismissals = 0;

      await tester.pumpWidget(
        _toastIn(
          Toast(
            key: UniqueKey(),
            message: ToastMessage(tone: tone, title: title, detail: detail),
            onDismiss: () => dismissals++,
          ),
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      final toast = tester.getRect(find.byType(Toast));
      final icon = tester.getRect(find.byType(DesignIcon).first);
      final iconWidget = tester.widget<DesignIcon>(
        find.byType(DesignIcon).first,
      );
      final titleBox = tester.getRect(find.text(title));
      final dismiss = tester.getRect(find.byType(ToastDismissButton));
      final stripe = tester.getRect(find.byType(ToastStripe));
      final titleStyle = renderedStyleOf(tester, title);

      expect(icon.left - toast.left, 17);
      expect(icon.top - toast.top, 13);
      expect(icon.size, const Size.square(20));
      expect(iconWidget.icon, _cssIcons[tone]);
      expect(iconWidget.color, _cssTone(tone, colors));
      expect(titleBox.left - icon.right, 12);
      expect(titleBox.top - toast.top, 13);
      expect(dismiss.size, const Size.square(28));
      expect(toast.right - dismiss.right, 13);
      expect(dismiss.left - titleBox.right, greaterThanOrEqualTo(12));
      expect(stripe.left - toast.left, 1);
      expect(stripe.width, 4);
      expect(stripe.top - toast.top, 1);
      expect(toast.bottom - stripe.bottom, 1);
      expect(titleStyle.fontSize, 14);
      expect(titleStyle.fontWeight, FontWeight.w600);
      expect(titleStyle.height, 1.4);

      if (detail != null) {
        final detailBox = tester.getRect(find.text(detail));
        final detailStyle = renderedStyleOf(tester, detail);

        expect(detailBox.top - titleBox.bottom, 4);
        expect(detailStyle.color, colors.inkSecondary);
        expect(detailStyle.height, 1.5);
        expect(toast.bottom - detailBox.bottom, 13);
      } else {
        expect(toast.bottom - dismiss.bottom, greaterThanOrEqualTo(13));
      }

      await tester.tap(find.byType(ToastDismissButton));

      expect(dismissals, 1);
    }
  });

  testWidgets('ToastStripe property sweeps the progress tone, unless reduced', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);

    for (final disableAnimations in [false, true]) {
      await tester.pumpWidget(
        _toastIn(
          Toast(
            key: UniqueKey(),
            message: const ToastMessage(
              tone: ToastTone.progress,
              title: 'Generating',
            ),
            onDismiss: () {},
          ),
          disableAnimations: disableAnimations,
        ),
      );

      final first = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(ToastStripe),
          matching: find.byType(DecoratedBox),
        ),
      );

      await tester.pump(const Duration(milliseconds: 900));

      final later = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(ToastStripe),
          matching: find.byType(DecoratedBox),
        ),
      );
      final firstDecoration = first.decoration as BoxDecoration;
      final laterDecoration = later.decoration as BoxDecoration;

      if (disableAnimations) {
        expect(laterDecoration.color, colors.brand);
        expect(laterDecoration.gradient, isNull);
      } else {
        final gradient = laterDecoration.gradient as LinearGradient;

        expect(gradient.colors, [
          colors.brandSurfaceStrong,
          colors.brand,
          colors.brand,
          colors.brandSurfaceStrong,
        ]);
        expect(gradient.stops, [0, 0.45, 0.55, 1]);
        expect(laterDecoration.gradient, isNot(firstDecoration.gradient));
      }
    }
  });

  testWidgets('ToastHost property shows what is left after any dismissals', (
    tester,
  ) async {
    for (final plan in examplesOf(
      (random) => [
        for (var index = 0; index < integerBetween(random, 1, 5); index++)
          random.nextBool(),
      ],
      runs: 6,
    )) {
      final hostKey = GlobalKey<ToastHostState>();

      await tester.pumpWidget(
        MaterialApp(
          home: ToastHost(key: hostKey, child: const SizedBox.expand()),
        ),
      );

      final kept = <String>[];

      for (var index = 0; index < plan.length; index++) {
        final title = 'Toast $index';
        final shown = hostKey.currentState?.show(
          ToastMessage(tone: ToastTone.success, title: title),
        );

        if (plan[index] && shown != null) {
          hostKey.currentState?.dismiss(shown);
        } else {
          kept.add(title);
        }
      }

      await tester.pumpAndSettle();

      final shownTitles = [
        for (final toast in tester.widgetList<Toast>(find.byType(Toast)))
          toast.message.title,
      ];

      expect(shownTitles, kept);

      final boxes = [
        for (final title in kept)
          tester.getRect(
            find.ancestor(of: find.text(title), matching: find.byType(Toast)),
          ),
      ];

      for (var index = 0; index < boxes.length; index++) {
        expect(boxes[index].width, 360);
        expect(boxes[index].right, 800 - 16);

        if (index > 0) {
          expect(boxes[index].top - boxes[index - 1].bottom, 8);
        }
      }

      if (boxes.isNotEmpty) {
        expect(boxes.last.bottom, 600 - 16);
      }
    }
  });

  testWidgets('ToastHost property closes a toast from its dismiss button', (
    tester,
  ) async {
    final hostKey = GlobalKey<ToastHostState>();

    await tester.pumpWidget(
      MaterialApp(
        home: ToastHost(key: hostKey, child: const SizedBox.expand()),
      ),
    );
    hostKey.currentState?.show(
      const ToastMessage(tone: ToastTone.failure, title: 'Broken'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ToastDismissButton));
    await tester.pumpAndSettle();

    expect(find.byType(Toast), findsNothing);
  });
}
