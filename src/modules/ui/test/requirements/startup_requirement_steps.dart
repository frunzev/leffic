import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/startup/startup_page.dart';
import 'package:leffic/shared/navigation/routes.dart';

import '../features/settings/settings_fakes.dart';
import '../support/backend_fakes.dart';
import '../support/hosting.dart';
import 'requirement_world.dart';
import 'step_definition.dart';

Future<void> _letBackendStart(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  world.relauncher = RecordingRelauncher();
}

Future<void> _stopBackendStarting(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  world.relauncher = RecordingRelauncher(failure: values.single);
}

Future<void> _openApp(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final startup = StartupPage(relaunchBackend: world.relauncher.relaunch);

  await tester.pumpWidget(
    hostedWithBackend(
      client: FakeBackend({}).client(),
      opened: world.openedRoutes,
      child: startup,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _checkHomeOpened(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  final opened = world.openedRoutes.single;
  final arguments = opened.arguments;

  expect(opened.name, Routes.folder);
  expect(arguments, isA<UnitArguments>());
  expect((arguments! as UnitArguments).id, homeFolderId);
}

final List<StepDefinition> startupStepDefinitions = [
  StepDefinition('Given', RegExp(r'^the backend starts$'), _letBackendStart),
  StepDefinition(
    'Given',
    RegExp(r'^the backend cannot start because "(.+)"$'),
    _stopBackendStarting,
  ),
  StepDefinition('When', RegExp(r'^the app opens$'), _openApp),
  StepDefinition('Then', RegExp(r'^the app opens home$'), _checkHomeOpened),
];
