import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/settings/ai_provider_panel.dart';
import 'package:leffic/features/settings/settings_layout.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/design_shadows.dart';
import 'package:leffic/shared/design/panel_look.dart';
import 'package:leffic/shared/design/surface_box.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const Key _bodyKey = Key('panel body');
const double _surfaceHeight = 1000;

Future<void> _pumpLayout(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, _surfaceHeight);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hostedPlainly(
      const SettingsLayout(
        panel: AiProviderPanel(body: SizedBox(key: _bodyKey, height: 300)),
      ),
    ),
  );
}

void main() {
  testWidgets('SettingsLayout property centres an 880 column at any width', (
    tester,
  ) async {
    for (final width in examplesOf(
      (random) => integerBetween(random, 952, 2400).toDouble(),
      runs: 8,
    )) {
      await _pumpLayout(tester, width);

      final columnLeft = (width - 880) / 2 + 32;
      final title = tester.getRect(find.text('Settings'));
      final navItem = tester.getRect(
        find
            .ancestor(
              of: find.text(aiProviderKeysTitle).first,
              matching: find.byType(Container),
            )
            .first,
      );
      final panel = tester.getRect(find.byType(AiProviderPanel));

      expect(title.left, closeTo(columnLeft, 1e-6));
      expect(title.top, 48);
      expect(navItem.left, closeTo(columnLeft, 1e-6));
      expect(navItem.size, const Size(208, 40));
      expect(navItem.top - title.bottom, closeTo(24, 1e-6));
      expect(panel.left - navItem.right, closeTo(32, 1e-6));
      expect(panel.width, closeTo(816 - 208 - 32, 1e-6));
      expect(panel.top, navItem.top);
    }
  });

  testWidgets('SettingsLayout property styles title, section and panel', (
    tester,
  ) async {
    final colors = DesignColors.forBrightness(Brightness.light);
    final shadows = DesignShadows.forBrightness(Brightness.light);

    await _pumpLayout(tester, 1368);

    final titleStyle = renderedStyleOf(tester, 'Settings');
    final sectionStyles = tester
        .widgetList<RichText>(
          find.descendant(
            of: find.text(aiProviderKeysTitle),
            matching: find.byType(RichText),
          ),
        )
        .map((paragraph) => paragraph.text.style!)
        .toList();
    final panelBox = tester.widget<SurfaceBox>(
      find.descendant(
        of: find.byType(AiProviderPanel),
        matching: find.byType(SurfaceBox),
      ),
    );
    final panel = tester.getRect(find.byType(AiProviderPanel));
    final panelTitle = tester.getRect(find.text(aiProviderKeysTitle).last);
    final panelText = tester.getRect(find.text(aiProviderKeysText));
    final body = tester.getRect(find.byKey(_bodyKey));
    final panelTextStyle = renderedStyleOf(tester, aiProviderKeysText);

    expect(titleStyle.fontSize, 24);
    expect(titleStyle.fontWeight, FontWeight.w600);
    expect(titleStyle.letterSpacing, closeTo(0.07 - 0.24, 1e-9));
    expect(sectionStyles.first.color, colors.brandStrong);
    expect(sectionStyles.first.fontSize, 14);
    expect(sectionStyles.first.fontWeight, FontWeight.w600);
    expect(sectionStyles.last.fontSize, 20);
    expect(sectionStyles.last.letterSpacing, closeTo(-0.45 - 0.2, 1e-9));
    expect(
      panelBox.look,
      isA<SurfaceLook>()
          .having((look) => look.fill, 'fill', colors.surface)
          .having(
            (look) => look.border,
            'border',
            BorderSide(color: colors.line),
          )
          .having((look) => look.shadows, 'shadows', shadows.raised),
    );
    expect(
      raisedPanelLookOf(colors: colors, shadows: shadows).edgeHighlight,
      panelBox.look.edgeHighlight,
    );
    expect(panelBox.borderRadius, 14);
    expect(panelTitle.left - panel.left, 25);
    expect(panelTitle.top - panel.top, 25);
    expect(panelText.top - panelTitle.bottom, closeTo(4, 1e-6));
    expect(body.top - panelText.bottom, closeTo(16, 1e-6));
    expect(panel.bottom - body.bottom, 25);
    expect(panelTextStyle.fontSize, 14);
    expect(panelTextStyle.color, colors.inkSecondary);
  });
}
