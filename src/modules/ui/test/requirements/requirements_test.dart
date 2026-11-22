import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/hosting.dart';
import 'ask_requirement_steps.dart';
import 'file_requirement_steps.dart';
import 'folder_requirement_steps.dart';
import 'gherkin_scenarios.dart';
import 'import_requirement_steps.dart';
import 'note_requirement_steps.dart';
import 'requirement_world.dart';
import 'review_requirement_steps.dart';
import 'settings_requirement_steps.dart';
import 'startup_requirement_steps.dart';
import 'step_definition.dart';
import 'test_requirement_steps.dart';

const String _requirementsDirectory = '../../../requirements';
const String _featureSuffix = '.feature';

final List<StepDefinition> _uiStepDefinitions = [
  ...folderStepDefinitions,
  ...reviewStepDefinitions,
  ...askStepDefinitions,
  ...noteStepDefinitions,
  ...settingsStepDefinitions,
  ...startupStepDefinitions,
  ...testStepDefinitions,
  ...fileStepDefinitions,
  ...importStepDefinitions,
  StepDefinition('Then', RegExp(r'^the app shows "(.+)"$'), _checkShown),
  StepDefinition('Then', RegExp(r'^the app offers "(.+)"$'), _checkShown),
];

Future<void> _checkShown(
  WidgetTester tester,
  UiWorld world,
  List<String> values,
) async {
  expect(find.text(values.single), findsWidgets);
}

Future<void> _runStep(
  WidgetTester tester,
  UiWorld world,
  GherkinStep step,
) async {
  for (final definition in _uiStepDefinitions) {
    final values = valuesMatching(definition, step);

    if (values != null) {
      await definition.action(tester, world, values);

      return;
    }
  }

  fail('No step definition for "${step.keyword} ${step.text}"');
}

Future<void> _runScenario(
  WidgetTester tester,
  GherkinScenario scenario,
) async {
  useDesktopSurface(tester);
  final world = UiWorld();

  for (final step in scenario.steps) {
    await _runStep(tester, world, step);
  }
}

List<GherkinScenario> _uiScenarios() {
  final featurePaths = <String>[];

  for (final entity in Directory(_requirementsDirectory).listSync()) {
    if (entity is File && entity.path.endsWith(_featureSuffix)) {
      featurePaths.add(entity.path);
    }
  }

  featurePaths.sort();

  final scenarios = <GherkinScenario>[];

  for (final featurePath in featurePaths) {
    final featureText = File(featurePath).readAsStringSync();
    scenarios.addAll(scenariosTagged(featureText, uiTag));
  }

  return scenarios;
}

void main() {
  final uiScenarios = _uiScenarios();

  test('the requirements folder holds the UI scenarios', () {
    expect(uiScenarios, isNotEmpty);
  });

  for (final scenario in uiScenarios) {
    testWidgets(scenario.name, (tester) => _runScenario(tester, scenario));
  }
}
