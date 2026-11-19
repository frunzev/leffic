import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/design_button.dart';
import 'package:leffic/shared/design/design_colors.dart';
import 'package:leffic/shared/design/icons/design_icons.dart';
import 'package:leffic/shared/design/toast_host.dart';
import 'package:leffic/shared/theme/leffic_theme.dart';
import 'package:leffic/shared/widgets/ask_panel_scope.dart';

import '../../test/support/system_fonts.dart';

const String _shotDirectory = String.fromEnvironment('DESIGN_SHOTS_DIRECTORY');
const Size desktopWindow = Size(1440, 900);
const Duration _settleTime = Duration(milliseconds: 400);
const int _settleFrames = 3;
const Key _shotKey = Key('design shot');

class ShotApp extends StatelessWidget {
  const ShotApp({
    required this.brightness,
    required this.askPanel,
    required this.panel,
    required this.home,
    super.key,
  });

  final Brightness brightness;
  final AskPanelController askPanel;
  final Widget panel;
  final Widget home;

  Widget _wrapPages(BuildContext context, Widget? pages) {
    return AskPanelScope(
      controller: askPanel,
      panel: panel,
      child: ToastHost(child: pages ?? const SizedBox.shrink()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _shotKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lefficTheme(brightness),
        darkTheme: lefficTheme(brightness),
        builder: _wrapPages,
        home: home,
      ),
    );
  }
}

Widget surfacePanelFor(Brightness brightness) {
  return ColoredBox(color: DesignColors.forBrightness(brightness).surface);
}

Future<void> pumpShotApp(
  WidgetTester tester, {
  required Brightness brightness,
  required AskPanelController askPanel,
  required Widget panel,
  required Widget home,
}) async {
  useDesktopWindow(tester);
  await tester.runAsync(loadSystemFonts);
  await tester.pumpWidget(
    ShotApp(
      brightness: brightness,
      askPanel: askPanel,
      panel: panel,
      home: home,
    ),
  );
}

void useDesktopWindow(WidgetTester tester) {
  if (_shotDirectory.isEmpty) {
    throw StateError('Pass --dart-define=DESIGN_SHOTS_DIRECTORY=<folder>');
  }

  debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
  debugDisableShadows = false;
  tester.view.physicalSize = desktopWindow;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void releaseDesktopWindow() {
  debugDefaultTargetPlatformOverride = null;
  debugDisableShadows = true;
}

Future<void> _writePicture(Element boundary, String slug) async {
  final image = await captureImage(boundary);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  if (bytes == null) {
    throw StateError('No picture of $slug could be encoded');
  }

  File('$_shotDirectory/$slug.png')
      .writeAsBytesSync(bytes.buffer.asUint8List());
}

String _slugFor(String name, Brightness brightness) {
  return brightness == Brightness.dark ? '$name-dark' : name;
}

Future<void> saveShot(
  WidgetTester tester,
  String name,
  Brightness brightness,
) async {
  for (var frame = 0; frame < _settleFrames; frame++) {
    await tester.pump(_settleTime);
  }

  final boundary = find.byKey(_shotKey).evaluate().single;
  final slug = _slugFor(name, brightness);

  await tester.runAsync(() => _writePicture(boundary, slug));
}

bool _isDotsMenuButton(Widget widget) {
  return widget is DesignIconButton && widget.icon == DesignIcons.dots;
}

Future<void> openDotsMenu(WidgetTester tester) async {
  await tester.tap(find.byWidgetPredicate(_isDotsMenuButton));
  await tester.pumpAndSettle();
}
