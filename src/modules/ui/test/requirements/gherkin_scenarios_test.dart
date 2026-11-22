import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import '../support/property.dart';
import 'gherkin_scenarios.dart';

class _WrittenRule {
  const _WrittenRule({
    required this.name,
    required this.isUi,
    required this.scenarioNames,
  });

  final String name;
  final bool isUi;
  final List<String> scenarioNames;
}

_WrittenRule _generatedRule(Random random, int ruleNumber) {
  final scenarioNames = <String>[];
  final scenarioCount = integerBetween(random, 1, 3);

  for (var index = 0; index < scenarioCount; index++) {
    scenarioNames.add('Scenario $ruleNumber.$index ${wordOf(random)}');
  }

  return _WrittenRule(
    name: 'Rule $ruleNumber ${wordOf(random)}',
    isUi: random.nextBool(),
    scenarioNames: scenarioNames,
  );
}

List<_WrittenRule> _generatedRules(Random random) {
  final rules = <_WrittenRule>[];
  final ruleCount = integerBetween(random, 1, 4);

  for (var ruleNumber = 0; ruleNumber < ruleCount; ruleNumber++) {
    rules.add(_generatedRule(random, ruleNumber));
  }

  return rules;
}

String _featureText(List<_WrittenRule> rules) {
  final lines = <String>['Feature: Generated', ''];

  for (final rule in rules) {
    if (rule.isUi) {
      lines.add('  $uiTag');
    }

    lines.add('  Rule: ${rule.name}');

    for (final scenarioName in rule.scenarioNames) {
      lines
        ..add('    Scenario: $scenarioName')
        ..add('      Given something exists')
        ..add('      And something else exists')
        ..add('      When I act on "$scenarioName"')
        ..add('      Then I see the result');
    }
  }

  return lines.join('\n');
}

void main() {
  test('scenariosTagged property reads exactly the UI scenarios', () {
    forAll(_generatedRules, (rules) {
      final read = scenariosTagged(_featureText(rules), uiTag);
      final expectedNames = <String>[];
      final readNames = <String>[];

      for (final rule in rules) {
        if (rule.isUi) {
          expectedNames.addAll(rule.scenarioNames);
        }
      }

      for (final scenario in read) {
        readNames.add(scenario.name);
      }

      expect(readNames, expectedNames);
    });
  });

  test('scenariosTagged property gives a conjunction its earlier kind', () {
    forAll(_generatedRules, (rules) {
      final everyRuleTagged = <_WrittenRule>[];

      for (final rule in rules) {
        everyRuleTagged.add(
          _WrittenRule(
            name: rule.name,
            isUi: true,
            scenarioNames: rule.scenarioNames,
          ),
        );
      }

      for (final scenario in scenariosTagged(
        _featureText(everyRuleTagged),
        uiTag,
      )) {
        final keywords = <String>[];

        for (final step in scenario.steps) {
          keywords.add(step.keyword);
        }

        expect(keywords, ['Given', 'Given', 'When', 'Then']);
        expect(scenario.steps[2].text, 'I act on "${scenario.name}"');
      }
    });
  });
}
