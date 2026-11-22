import 'package:flutter_test/flutter_test.dart';

import 'gherkin_scenarios.dart';
import 'requirement_world.dart';

typedef StepAction =
    Future<void> Function(
      WidgetTester tester,
      UiWorld world,
      List<String> values,
    );

class StepDefinition {
  const StepDefinition(this.keyword, this.pattern, this.action);

  final String keyword;
  final RegExp pattern;
  final StepAction action;
}

List<String>? valuesMatching(StepDefinition definition, GherkinStep step) {
  if (definition.keyword != step.keyword) {
    return null;
  }

  final match = definition.pattern.firstMatch(step.text);

  if (match == null) {
    return null;
  }

  final values = <String>[];

  for (var index = 1; index <= match.groupCount; index++) {
    values.add(match.group(index) ?? '');
  }

  return values;
}
