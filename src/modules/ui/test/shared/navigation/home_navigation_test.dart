import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/navigation/home_navigation.dart';
import 'package:leffic/shared/navigation/routes.dart';

import '../../support/property.dart';

const String _goHomeLabel = 'go home';

class _Navigation {
  final List<RouteSettings> opened = [];

  Route<void> open(RouteSettings settings) {
    opened.add(settings);

    return MaterialPageRoute<void>(settings: settings, builder: _page);
  }

  Widget _page(BuildContext context) {
    return Scaffold(
      body: TextButton(
        onPressed: () => openHomeFolder(context),
        child: const Text(_goHomeLabel),
      ),
    );
  }
}

void main() {
  testWidgets('openHomeFolder property keeps only the first page below Home', (
    tester,
  ) async {
    for (final depth in examplesOf(
      (random) => integerBetween(random, 0, 4),
      runs: 5,
    )) {
      final navigation = _Navigation();

      await tester.pumpWidget(
        MaterialApp(key: UniqueKey(), onGenerateRoute: navigation.open),
      );

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));

      for (var level = 0; level < depth; level++) {
        navigator.pushNamed('/level-$level').ignore();
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text(_goHomeLabel));
      await tester.pumpAndSettle();

      final home = navigation.opened.last;

      expect(home.name, Routes.folder);
      expect((home.arguments! as UnitArguments).id, homeFolderId);

      navigator.pop();
      await tester.pumpAndSettle();

      expect(navigator.canPop(), isFalse);
    }
  });
}
