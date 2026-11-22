const String uiTag = '@ui';

const String _featureKeyword = 'Feature:';
const String _ruleKeyword = 'Rule:';
const String _scenarioKeyword = 'Scenario:';
const String _tagMarker = '@';
const String _commentMarker = '#';
const String _firstStepKeyword = 'Given';
const List<String> _stepKeywords = ['Given', 'When', 'Then'];
const List<String> _conjunctions = ['And', 'But'];

class GherkinStep {
  const GherkinStep({required this.keyword, required this.text});

  final String keyword;
  final String text;
}

class GherkinScenario {
  const GherkinScenario({
    required this.name,
    required this.tags,
    required this.steps,
  });

  final String name;
  final Set<String> tags;
  final List<GherkinStep> steps;
}

class _ScenarioReader {
  final List<GherkinScenario> scenarios = [];
  Set<String> _pendingTags = {};
  Set<String> _featureTags = {};
  Set<String> _ruleTags = {};
  String? _scenarioName;
  Set<String> _scenarioTags = {};
  List<GherkinStep> _steps = [];
  String _lastKeyword = _firstStepKeyword;

  void read(String line) {
    final text = line.trim();

    if (text.isEmpty || text.startsWith(_commentMarker)) {
      return;
    }

    if (text.startsWith(_tagMarker)) {
      _pendingTags.addAll(text.split(RegExp(r'\s+')));
    } else if (text.startsWith(_featureKeyword)) {
      _featureTags = _takePendingTags();
    } else if (text.startsWith(_ruleKeyword)) {
      finishScenario();
      _ruleTags = _takePendingTags();
    } else if (text.startsWith(_scenarioKeyword)) {
      _startScenario(text.substring(_scenarioKeyword.length).trim());
    } else {
      _readStep(text);
    }
  }

  void finishScenario() {
    final scenarioName = _scenarioName;

    if (scenarioName == null) {
      return;
    }

    scenarios.add(
      GherkinScenario(name: scenarioName, tags: _scenarioTags, steps: _steps),
    );
    _scenarioName = null;
  }

  Set<String> _takePendingTags() {
    final tags = _pendingTags;
    _pendingTags = {};

    return tags;
  }

  void _startScenario(String scenarioName) {
    finishScenario();
    _scenarioName = scenarioName;
    _scenarioTags = {..._featureTags, ..._ruleTags, ..._takePendingTags()};
    _steps = [];
    _lastKeyword = _firstStepKeyword;
  }

  void _readStep(String text) {
    final firstSpace = text.indexOf(' ');

    if (_scenarioName == null || firstSpace < 0) {
      return;
    }

    final writtenKeyword = text.substring(0, firstSpace);
    final stepText = text.substring(firstSpace + 1).trim();

    if (_conjunctions.contains(writtenKeyword)) {
      _steps.add(GherkinStep(keyword: _lastKeyword, text: stepText));
    } else if (_stepKeywords.contains(writtenKeyword)) {
      _lastKeyword = writtenKeyword;
      _steps.add(GherkinStep(keyword: writtenKeyword, text: stepText));
    }
  }
}

List<GherkinScenario> scenariosTagged(String featureText, String tag) {
  final reader = _ScenarioReader();

  for (final line in featureText.split('\n')) {
    reader.read(line);
  }

  reader.finishScenario();

  final tagged = <GherkinScenario>[];

  for (final scenario in reader.scenarios) {
    if (scenario.tags.contains(tag)) {
      tagged.add(scenario);
    }
  }

  return tagged;
}
