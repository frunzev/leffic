import '../../shared/api/json_reading.dart';

sealed class TestAnswer {
  const TestAnswer();

  factory TestAnswer.fromWire(Object? wireValue) {
    if (wireValue is int) {
      return ChosenOption(wireValue);
    }

    if (wireValue is String) {
      return TypedAnswer(wireValue);
    }

    throw const FormatException('Expected an option id or a typed answer');
  }

  Object get wireValue;
}

class ChosenOption extends TestAnswer {
  const ChosenOption(this.optionId);

  final int optionId;

  @override
  Object get wireValue => optionId;
}

class TypedAnswer extends TestAnswer {
  const TypedAnswer(this.text);

  final String text;

  @override
  Object get wireValue => text;
}

List<TestAnswer> readTestAnswers(JsonObject json, String key) {
  final storedAnswers = json[key];

  if (storedAnswers == null) {
    return const [];
  }

  if (storedAnswers is! List<Object?>) {
    throw FormatException('Expected a list at "$key"');
  }

  final answers = <TestAnswer>[];

  for (final storedAnswer in storedAnswers) {
    answers.add(TestAnswer.fromWire(storedAnswer));
  }

  return answers;
}

bool isOptionChosen(List<TestAnswer> answers, int optionId) {
  for (final answer in answers) {
    if (answer is ChosenOption && answer.optionId == optionId) {
      return true;
    }
  }

  return false;
}

String typedTextOf(List<TestAnswer> answers) {
  for (final answer in answers) {
    if (answer is TypedAnswer) {
      return answer.text;
    }
  }

  return '';
}
