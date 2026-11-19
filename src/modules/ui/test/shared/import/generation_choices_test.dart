import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/import/amount_choice.dart';
import 'package:leffic/shared/import/generation_choices.dart';

import '../../support/property.dart';
import 'import_fakes.dart';

void main() {
  test('GeneratedSetChoice.amountChoiceOf property is Auto until set', () {
    forAll(
      (random) => (
        generatedSetChoice(random, flashcardTypeOptions),
        oneOf(random, flashcardTypeOptions).id,
      ),
      (example) {
        final (choice, typeId) = example;
        final amountChoice = choice.amountChoiceOf(typeId);
        final setAmountChoice = choice.amountChoices[typeId];

        if (setAmountChoice == null) {
          expect(amountChoice, AmountChoice.automatic);
          return;
        }

        expect(amountChoice, setAmountChoice);
      },
    );
  });

  test('GeneratedSetChoice.toggled property flips only the choice', () {
    forAll((random) => generatedSetChoice(random, flashcardTypeOptions), (
      choice,
    ) {
      final toggled = choice.toggled();

      expect(toggled.isChosen, !choice.isChosen);
      expect(toggled.chosenTypeIds, choice.chosenTypeIds);
      expect(toggled.amountChoices, choice.amountChoices);
      expect(toggled.toggled().isChosen, choice.isChosen);
    });
  });

  test('GeneratedSetChoice.withTypeToggled property is its own inverse', () {
    forAll(
      (random) => (
        generatedSetChoice(random, testTypeOptions),
        oneOf(random, testTypeOptions).id,
      ),
      (example) {
        final (choice, typeId) = example;
        final once = choice.withTypeToggled(typeId);
        final twice = once.withTypeToggled(typeId);

        expect(
          once.chosenTypeIds.contains(typeId),
          isNot(choice.chosenTypeIds.contains(typeId)),
        );
        expect(twice.chosenTypeIds.toSet(), choice.chosenTypeIds.toSet());
        expect(once.isChosen, choice.isChosen);
        expect(once.amountChoices, choice.amountChoices);
      },
    );
  });

  test('GeneratedSetChoice.withAmountChoice property changes one type', () {
    forAll(
      (random) => (
        generatedSetChoice(random, flashcardTypeOptions),
        oneOf(random, flashcardTypeOptions).id,
        generatedAmountChoice(random),
      ),
      (example) {
        final (choice, changedTypeId, amountChoice) = example;
        final changed = choice.withAmountChoice(
          typeId: changedTypeId,
          amountChoice: amountChoice,
        );

        expect(changed.amountChoiceOf(changedTypeId), amountChoice);
        expect(changed.chosenTypeIds, choice.chosenTypeIds);
        expect(changed.isChosen, choice.isChosen);

        for (final option in flashcardTypeOptions) {
          if (option.id != changedTypeId) {
            expect(
              changed.amountChoiceOf(option.id),
              choice.amountChoiceOf(option.id),
            );
          }
        }
      },
    );
  });

  test('GeneratedSetChoice.toJson property sends each type its own amount', () {
    forAll((random) => generatedSetChoice(random, testTypeOptions), (choice) {
      final json = choice.toJson();
      final amounts = json['amounts'] as Map<String, Object?>;

      expect(json.keys, unorderedEquals(['types', 'amounts']));
      expect(json['types'], choice.chosenTypeIds);
      expect(choice.chosenTypeIds, containsAll(amounts.keys));

      for (final typeId in choice.chosenTypeIds) {
        final amount = choice.amountChoiceOf(typeId).amount;

        expect(amounts.containsKey(typeId), amount != null);
        expect(amounts[typeId], amount);
      }

      expect(
        choice.isRequested,
        choice.isChosen && choice.chosenTypeIds.isNotEmpty,
      );
    });
  });

  test('GenerationChoices.toJson property asks for exactly what is wanted', () {
    forAll(generatedChoices, (choices) {
      final json = choices.toJson();

      expect(json.containsKey('note'), choices.isNoteChosen);
      expect(json.containsKey('flashcards'), choices.flashcards.isRequested);
      expect(json.containsKey('test'), choices.test.isRequested);
      expect(choices.isAnythingRequested, json.isNotEmpty);
    });
  });

  test('GenerationChoices property replaces one part at a time', () {
    forAll((random) => (generatedChoices(random), generatedChoices(random)), (
      example,
    ) {
      final (choices, other) = example;
      final withFlashcards = choices.withFlashcards(other.flashcards);
      final withTest = choices.withTest(other.test);
      final withNote = choices.withNoteToggled();

      expect(withFlashcards.flashcards, other.flashcards);
      expect(withFlashcards.test, choices.test);
      expect(withTest.test, other.test);
      expect(withTest.isNoteChosen, choices.isNoteChosen);
      expect(withNote.isNoteChosen, !choices.isNoteChosen);
      expect(withNote.flashcards, choices.flashcards);
    });
  });

  test('GenerationChoices.starting property asks for every kind on Auto', () {
    final starting = GenerationChoices.starting;
    final json = starting.toJson();

    forAll((random) => oneOf(random, ['note', 'flashcards', 'test']), (key) {
      expect(json.containsKey(key), isTrue);
    });
    expect(starting.flashcards.chosenTypeIds, ['basic']);
    expect(starting.test.chosenTypeIds, ['multiple_choice']);
    expect(starting.flashcards.amountChoices, isEmpty);
    expect(starting.test.amountChoices, isEmpty);
  });

  test('StudyUnitTypeOption property explains only the Feynman type', () {
    forAll(
      (random) => oneOf(random, [...flashcardTypeOptions, ...testTypeOptions]),
      (option) {
        final explanation = option.explanation;

        if (option.id != 'feynman') {
          expect(explanation, isNull);
          return;
        }

        expect(explanation?.question, 'What are Feynman cards?');
        expect(
          explanation?.answer,
          'Feynman cards ask you to explain a concept step by step, '
          'in your own words.',
        );
      },
    );
  });
}
