import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/api/api_client.dart';
import 'package:leffic/shared/design/toast_host.dart';
import 'package:leffic/shared/session/backend_scope.dart';
import 'package:leffic/shared/theme/leffic_theme.dart';
import 'package:leffic/shared/widgets/ask_panel_scope.dart';

const String folderPageText = 'folder page';
const String _openedPageText = 'opened page';
const Size _desktopSurface = Size(1400, 1400);

class _RouteRecorder {
  const _RouteRecorder(this.opened);

  final List<RouteSettings> opened;

  Route<void> open(RouteSettings settings) {
    opened.add(settings);

    return MaterialPageRoute<void>(settings: settings, builder: _openedPage);
  }
}

Widget _openedPage(BuildContext context) {
  return const Scaffold(body: Text(_openedPageText));
}

Widget withShellScopes(BuildContext context, Widget? navigator) {
  return AskPanelScope(
    controller: AskPanelController(),
    panel: const SizedBox.shrink(),
    child: ToastHost(child: navigator ?? const SizedBox.shrink()),
  );
}

Widget hostedPlainly(Widget child) {
  return MaterialApp(
    key: UniqueKey(),
    builder: withShellScopes,
    home: Scaffold(body: child),
  );
}

Widget hostedInTheme(Widget child, {required Brightness brightness}) {
  return MaterialApp(
    key: UniqueKey(),
    theme: lefficTheme(brightness),
    builder: withShellScopes,
    home: Scaffold(body: child),
  );
}

Widget hostedInLightTheme(Widget child) {
  return hostedInTheme(child, brightness: Brightness.light);
}

Widget hostedWithBackend({
  required ApiClient client,
  required Widget child,
  required List<RouteSettings> opened,
}) {
  final link = BackendLink()..value = client;

  return BackendScope(
    link: link,
    child: MaterialApp(
      builder: withShellScopes,
      home: child,
      onGenerateRoute: _RouteRecorder(opened).open,
    ),
  );
}

Future<void> pumpOnTopOfFolder(
  WidgetTester tester, {
  required ApiClient client,
  required Widget page,
}) async {
  final link = BackendLink()..value = client;

  await tester.pumpWidget(
    BackendScope(
      link: link,
      child: MaterialApp(
        key: UniqueKey(),
        builder: withShellScopes,
        home: const Scaffold(body: Text(folderPageText)),
      ),
    ),
  );

  final navigator = tester.state<NavigatorState>(find.byType(Navigator));

  unawaited(
    navigator.push(MaterialPageRoute<void>(builder: (context) => page)),
  );
  await tester.pumpAndSettle();
}

void useDesktopSurface(WidgetTester tester) {
  tester.view.physicalSize = _desktopSurface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
