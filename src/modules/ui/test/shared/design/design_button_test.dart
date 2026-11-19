import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/button_look.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_shadows.dart';
import 'package:leffic/shared/design/focus_outline.dart';
import 'package:leffic/shared/design/icons/design_icon.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';
import 'package:leffic/shared/design/pressable.dart';
import 'package:leffic/shared/design/shortcut_chip.dart';
import 'package:leffic/shared/design/surface_box.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

typedef _ButtonExample = ({
  String label,
  ButtonSize size,
  ButtonVariant variant,
  DesignIcons? icon,
});

const Map<ButtonSize, ({double height, double padding, double fontSize})>
_cssSizes = {
  ButtonSize.small: (height: 34, padding: 12, fontSize: 14),
  ButtonSize.regular: (height: 40, padding: 16, fontSize: 14),
  ButtonSize.large: (height: 44, padding: 24, fontSize: 16),
};

List<_ButtonExample> _buttonExamples() {
  return examplesOf(
    (random) => (
      label: wordOf(random, maximum: 12),
      size: oneOf(random, ButtonSize.values),
      variant: oneOf(random, ButtonVariant.values),
      icon: oneOf(random, [null, ...DesignIcons.values]),
    ),
    runs: 16,
  );
}

void main() {
  testWidgets('DesignButton property sizes itself like every .btn size', (
    tester,
  ) async {
    for (final example in _buttonExamples()) {
      await tester.pumpWidget(
        hostedPlainly(
          Center(
            child: DesignButton(
              label: example.label,
              icon: example.icon,
              size: example.size,
              variant: example.variant,
              onPressed: () {},
            ),
          ),
        ),
      );

      final css = _cssSizes[example.size];
      final button = tester.getRect(find.byType(DesignButton));
      final label = tester.getRect(find.text(example.label));
      final style = renderedStyleOf(tester, example.label);
      final firstContent = example.icon == null
          ? label
          : tester.getRect(find.byType(DesignIcon));

      expect(button.height, css?.height);
      expect(firstContent.left - button.left, (css?.padding ?? 0) + 1);
      expect(button.right - label.right, (css?.padding ?? 0) + 1);
      expect(style.fontSize, css?.fontSize);
      expect(style.fontWeight, FontWeight.w500);
      expect(label.center.dy, closeTo(button.center.dy, 0.5));

      if (example.icon != null) {
        expect(firstContent.size, const Size.square(18));
        expect(label.left - firstContent.right, 8);
      }
    }
  });

  testWidgets('DesignButton property fires only while it has a callback', (
    tester,
  ) async {
    for (final example in _buttonExamples().take(6)) {
      var presses = 0;

      for (final isEnabled in [true, false]) {
        await tester.pumpWidget(
          hostedPlainly(
            Center(
              child: DesignButton(
                label: example.label,
                variant: example.variant,
                onPressed: isEnabled ? () => presses++ : null,
              ),
            ),
          ),
        );
        await tester.tap(find.text(example.label));
        await tester.pump();
      }

      expect(presses, 1);
    }
  });

  testWidgets('DesignButton property puts a trailing chip after the label', (
    tester,
  ) async {
    for (final label in examplesOf(wordOf, runs: 4)) {
      await tester.pumpWidget(
        hostedPlainly(
          Center(
            child: DesignButton(
              label: label,
              variant: ButtonVariant.primary,
              trailing: const ShortcutChip(
                label: 'Space',
                tone: ShortcutChipTone.onBrand,
              ),
              onPressed: () {},
            ),
          ),
        ),
      );

      final labelBox = tester.getRect(find.text(label));
      final chip = tester.getRect(find.byType(ShortcutChip));

      expect(chip.left - labelBox.right, 8);
    }
  });

  testWidgets('DesignButton property rings itself on keyboard focus', (
    tester,
  ) async {
    await tester.pumpWidget(
      hostedPlainly(
        Center(
          child: DesignButton(label: 'Save', onPressed: () {}),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    final painted = tester.widget<CustomPaint>(
      find
          .descendant(
            of: find.byType(FocusOutline),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    final painter = painted.foregroundPainter as FocusOutlinePainter;

    expect(painter.color, DesignColors.forBrightness(Brightness.light).brand);
    expect(painter.borderRadius, 10);
  });

  testWidgets('DesignButton property draws the .btn.is-done look', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      final colors = DesignColors.forBrightness(brightness);

      await tester.pumpWidget(
        hostedInTheme(
          const Center(
            child: DesignButton(
              label: 'Marked as read',
              icon: DesignIcons.success,
              variant: ButtonVariant.done,
              onPressed: null,
            ),
          ),
          brightness: brightness,
        ),
      );

      final button = find.byType(DesignButton);
      final surface = tester.widget<SurfaceBox>(
        find.descendant(of: button, matching: find.byType(SurfaceBox)),
      );
      final icon = tester.widget<DesignIcon>(find.byType(DesignIcon));
      final label = renderedStyleOf(tester, 'Marked as read');
      final buttonBox = tester.getRect(button);
      final iconBox = tester.getRect(find.byType(DesignIcon));
      final labelBox = tester.getRect(find.text('Marked as read'));

      expect(buttonBox.height, 40);
      expect(surface.borderRadius, 10);
      expect(surface.look.fill, colors.surface);
      expect(surface.look.border, BorderSide(color: colors.success));
      expect(surface.look.shadows, isEmpty);
      expect(icon.color, colors.success);
      expect(icon.size, 18);
      expect(label.fontSize, 14);
      expect(label.fontWeight, FontWeight.w500);
      expect(label.color, colors.inkSecondary);
      expect(iconBox.left - buttonBox.left, 17);
      expect(labelBox.left - iconBox.right, 8);
      expect(buttonBox.right - labelBox.right, 17);
    }
  });

  testWidgets('DesignIconButton property paints the icon colour it is given', (
    tester,
  ) async {
    for (final (variant, iconColor) in examplesOf(
      (random) => (
        oneOf(random, ButtonVariant.values),
        oneOf(random, [null, Color(random.nextInt(0xFFFFFF) | 0xFF000000)]),
      ),
      runs: 10,
    )) {
      await tester.pumpWidget(
        hostedPlainly(
          Center(
            child: DesignIconButton(
              icon: DesignIcons.bookmark,
              semanticLabel: 'Bookmark',
              variant: variant,
              iconColor: iconColor,
              onPressed: () {},
            ),
          ),
        ),
      );

      final element = tester.element(find.byType(DesignIconButton));
      final look = buttonLookOf(
        variant: variant,
        state: const InteractionState(
          isEnabled: true,
          isHovered: false,
          isPressed: false,
          isFocused: false,
        ),
        colors: DesignColors.of(element),
        shadows: DesignShadows.of(element),
      );
      final icon = tester.widget<DesignIcon>(find.byType(DesignIcon));

      expect(icon.color, iconColor ?? look.iconColor);
    }
  });

  testWidgets('DesignIconButton property is a square icon control', (
    tester,
  ) async {
    for (final (icon, variant, dimension) in examplesOf(
      (random) => (
        oneOf(random, DesignIcons.values),
        oneOf(random, ButtonVariant.values),
        oneOf(random, [34.0, 40.0]),
      ),
      runs: 10,
    )) {
      var presses = 0;

      await tester.pumpWidget(
        hostedPlainly(
          Center(
            child: DesignIconButton(
              icon: icon,
              semanticLabel: 'Close ${icon.name}',
              variant: variant,
              dimension: dimension,
              onPressed: () => presses++,
            ),
          ),
        ),
      );

      final button = tester.getRect(find.byType(DesignIconButton));
      final glyph = tester.getRect(find.byType(DesignIcon));

      expect(button.size, Size.square(dimension));
      expect(glyph.size, const Size.square(18));
      expect(glyph.center, button.center);
      expect(find.bySemanticsLabel('Close ${icon.name}'), findsOneWidget);

      await tester.tap(find.byType(DesignIconButton));
      expect(presses, 1);
    }
  });
}
