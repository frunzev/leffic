import '../api/json_reading.dart';
import 'amount_choice.dart';

class TypeExplanation {
  const TypeExplanation({required this.question, required this.answer});

  final String question;
  final String answer;
}

class StudyUnitTypeOption {
  const StudyUnitTypeOption({
    required this.id,
    required this.label,
    this.explanation,
  });

  final String id;
  final String label;
  final TypeExplanation? explanation;
}

const List<StudyUnitTypeOption> flashcardTypeOptions = [
  StudyUnitTypeOption(id: 'basic', label: 'Basic'),
  StudyUnitTypeOption(id: 'cloze', label: 'Fill in the blank'),
  StudyUnitTypeOption(id: 'list', label: 'List'),
  StudyUnitTypeOption(
    id: 'feynman',
    label: 'Feynman',
    explanation: TypeExplanation(
      question: 'What are Feynman cards?',
      answer:
          'Feynman cards ask you to explain a concept step by step, '
          'in your own words.',
    ),
  ),
];

const List<StudyUnitTypeOption> testTypeOptions = [
  StudyUnitTypeOption(id: 'multiple_choice', label: 'Multiple choice'),
  StudyUnitTypeOption(id: 'true_or_false', label: 'True or false'),
  StudyUnitTypeOption(id: 'short_answer', label: 'Short answer'),
];

class GeneratedSetChoice {
  const GeneratedSetChoice({
    required this.isChosen,
    required this.chosenTypeIds,
    required this.amountChoices,
  });

  final bool isChosen;
  final List<String> chosenTypeIds;
  final Map<String, AmountChoice> amountChoices;

  bool get isRequested => isChosen && chosenTypeIds.isNotEmpty;

  AmountChoice amountChoiceOf(String typeId) {
    return amountChoices[typeId] ?? AmountChoice.automatic;
  }

  GeneratedSetChoice toggled() {
    return GeneratedSetChoice(
      isChosen: !isChosen,
      chosenTypeIds: chosenTypeIds,
      amountChoices: amountChoices,
    );
  }

  GeneratedSetChoice withTypeToggled(String typeId) {
    final typeIds = List<String>.of(chosenTypeIds);

    if (typeIds.contains(typeId)) {
      typeIds.remove(typeId);
    } else {
      typeIds.add(typeId);
    }

    return GeneratedSetChoice(
      isChosen: isChosen,
      chosenTypeIds: typeIds,
      amountChoices: amountChoices,
    );
  }

  GeneratedSetChoice withAmountChoice({
    required String typeId,
    required AmountChoice amountChoice,
  }) {
    final changedAmountChoices = Map<String, AmountChoice>.of(amountChoices);

    changedAmountChoices[typeId] = amountChoice;

    return GeneratedSetChoice(
      isChosen: isChosen,
      chosenTypeIds: chosenTypeIds,
      amountChoices: changedAmountChoices,
    );
  }

  JsonObject toJson() {
    final amounts = <String, int>{};

    for (final typeId in chosenTypeIds) {
      final amount = amountChoiceOf(typeId).amount;

      if (amount != null) {
        amounts[typeId] = amount;
      }
    }

    return {'types': chosenTypeIds, 'amounts': amounts};
  }
}

class GenerationChoices {
  const GenerationChoices({
    required this.flashcards,
    required this.test,
    required this.isNoteChosen,
  });

  static const GenerationChoices starting = GenerationChoices(
    flashcards: GeneratedSetChoice(
      isChosen: true,
      chosenTypeIds: ['basic'],
      amountChoices: {},
    ),
    test: GeneratedSetChoice(
      isChosen: true,
      chosenTypeIds: ['multiple_choice'],
      amountChoices: {},
    ),
    isNoteChosen: true,
  );

  final GeneratedSetChoice flashcards;
  final GeneratedSetChoice test;
  final bool isNoteChosen;

  bool get isAnythingRequested {
    return isNoteChosen || flashcards.isRequested || test.isRequested;
  }

  GenerationChoices withFlashcards(GeneratedSetChoice newFlashcards) {
    return GenerationChoices(
      flashcards: newFlashcards,
      test: test,
      isNoteChosen: isNoteChosen,
    );
  }

  GenerationChoices withTest(GeneratedSetChoice newTest) {
    return GenerationChoices(
      flashcards: flashcards,
      test: newTest,
      isNoteChosen: isNoteChosen,
    );
  }

  GenerationChoices withNoteToggled() {
    return GenerationChoices(
      flashcards: flashcards,
      test: test,
      isNoteChosen: !isNoteChosen,
    );
  }

  JsonObject toJson() {
    return {
      if (isNoteChosen) 'note': <String, Object?>{},
      if (flashcards.isRequested) 'flashcards': flashcards.toJson(),
      if (test.isRequested) 'test': test.toJson(),
    };
  }
}
