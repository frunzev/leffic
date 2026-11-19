import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/opaque_page_route.dart';
import 'package:leffic/shared/theme/leffic_theme.dart';

import '../../support/property.dart';

Widget _namedPage(RouteSettings settings) {
  return Text('page ${settings.name}');
}

void main() {
  test('OpaquePageRoute property is opaque and has no transition', () {
    forAll(wordOf, (name) {
      final route = OpaquePageRoute(
        settings: RouteSettings(name: '/$name'),
        pageFor: _namedPage,
      );

      expect(route.opaque, isTrue);
      expect(route.maintainState, isTrue);
      expect(route.transitionDuration, Duration.zero);
      expect(route.reverseTransitionDuration, Duration.zero);
      expect(route.barrierColor, isNull);
    });
  });

  testWidgets('OpaquePageRoute property builds the page its settings name', (
    tester,
  ) async {
    for (final name in examplesOf(wordOf, runs: 6)) {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          MaterialApp(
            key: UniqueKey(),
            theme: lefficTheme(brightness),
            darkTheme: lefficTheme(brightness),
            initialRoute: '/$name',
            onGenerateRoute: (settings) =>
                OpaquePageRoute(settings: settings, pageFor: _namedPage),
          ),
        );

        final page = find.text('page /$name');
        final background = tester.widget<ColoredBox>(
          find.ancestor(of: page, matching: find.byType(ColoredBox)).first,
        );

        expect(page, findsOneWidget);
        expect(
          background.color,
          DesignColors.forBrightness(brightness).surfaceSecondary,
        );
      }
    }
  });

  testWidgets('OpaquePageRoute property hides the page underneath at once', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/first',
        onGenerateRoute: (settings) =>
            OpaquePageRoute(settings: settings, pageFor: _namedPage),
      ),
    );

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));

    navigator.pushNamed<void>('/second').ignore();
    await tester.pump();

    expect(find.text('page /second'), findsOneWidget);
    expect(find.text('page /first'), findsNothing);
  });
}
