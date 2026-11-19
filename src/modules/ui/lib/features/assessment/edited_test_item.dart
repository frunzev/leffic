import '../../shared/api/json_reading.dart';
import 'assessment_models.dart';

const int _correctOptionId = 0;

class EditedTestItem {
  const EditedTestItem({
    required this.question,
    required this.correctAnswer,
    required this.wrongAnswers,
  });

  factory EditedTestItem.fromAnswers({
    required String question,
    required List<String> answers,
    required int correctIndex,
  }) {
    final wrongAnswers = <String>[];

    for (var index = 0; index < answers.length; index++) {
      if (index != correctIndex) {
        wrongAnswers.add(answers[index].trim());
      }
    }

    return EditedTestItem(
      question: question.trim(),
      correctAnswer: answers[correctIndex].trim(),
      wrongAnswers: wrongAnswers,
    );
  }

  final String question;
  final String correctAnswer;
  final List<String> wrongAnswers;

  JsonObject toContent() {
    return {
      'question': question,
      'true_option': correctAnswer,
      'false_options': wrongAnswers,
    };
  }
}

bool isDraftIncomplete({
  required String question,
  required List<String> answers,
}) {
  if (question.trim().isEmpty || answers.isEmpty) {
    return true;
  }

  for (final answer in answers) {
    if (answer.trim().isEmpty) {
      return true;
    }
  }

  return false;
}

int correctIndexAfterRemoval({
  required int correctIndex,
  required int removedIndex,
}) {
  if (correctIndex >= removedIndex && correctIndex > 0) {
    return correctIndex - 1;
  }

  return correctIndex;
}

int initialCorrectIndex(List<TestOption> options) {
  for (var index = 0; index < options.length; index++) {
    if (options[index].id == _correctOptionId) {
      return index;
    }
  }

  return 0;
}
