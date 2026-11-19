import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/navigation/routes.dart';
import 'package:leffic/shared/widgets/app_shell.dart';
import 'package:leffic/shared/widgets/ask_panel_scope.dart';
import 'package:leffic/shared/widgets/rail_item.dart';

const Key shellBodyKey = Key('page body');
const Key askPanelKey = Key('ask panel');
const Size shellWindow = Size(1440, 900);
const List<String> shellRoutes = [
  Routes.folder,
  Routes.deckReview,
  Routes.folderReview,
  Routes.test,
  Routes.folderTest,
  Routes.note,
  Routes.file,
  Routes.settings,
];

class ShellHarness {
  ShellHarness(this.selectedRoute);

  final String selectedRoute;
  final AskPanelController askPanel = AskPanelController();
  final List<String?> opened = [];

  Widget wrap(BuildContext context, Widget? navigator) {
    return AskPanelScope(
      controller: askPanel,
      panel: const ColoredBox(key: askPanelKey, color: Color(0xFF00FF00)),
      child: navigator ?? const SizedBox(),
    );
  }

  Widget shellPage(BuildContext context) {
    return AppShell(
      selectedRoute: selectedRoute,
      body: const SizedBox.expand(key: shellBodyKey),
    );
  }

  Route<void> open(RouteSettings settings) {
    opened.add(settings.name);

    return MaterialPageRoute<void>(settings: settings, builder: shellPage);
  }

  Widget app() {
    return MaterialApp(key: UniqueKey(), builder: wrap, onGenerateRoute: open);
  }
}

Future<ShellHarness> pumpShell(
  WidgetTester tester,
  String selectedRoute, {
  Size surface = shellWindow,
}) async {
  final harness = ShellHarness(selectedRoute);

  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(harness.app());
  await tester.pumpAndSettle();

  return harness;
}

RailItem railItemLabelled(WidgetTester tester, String label) {
  return tester.widget<RailItem>(
    find.ancestor(of: find.text(label), matching: find.byType(RailItem)),
  );
}
