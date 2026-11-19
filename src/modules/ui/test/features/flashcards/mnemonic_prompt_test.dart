import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/flashcards/mnemonic_prompt.dart';

import '../../support/property.dart';

const String _titleStart = 'Mnemonic for: ';
const int _shownLimit = 60;
const List<String> _sections = [
  'ROLE\n',
  'TASK\n',
  'CONTEXT\n',
  'CONSTRAINTS\n',
  'OUTPUT\n',
];

void main() {
  test('mnemonicPrompt property quotes the question and the answer', () {
    forAll((random) => (anyTextOf(random), anyTextOf(random)), (example) {
      final (question, answer) = example;
      final prompt = mnemonicPrompt(question: question, answer: answer);

      expect(
        prompt,
        contains('Flashcard question: $question\nFlashcard answer: $answer\n'),
      );
    });
  });

  test('mnemonicPrompt property keeps its sections in order', () {
    forAll((random) => (wordOf(random), wordOf(random)), (example) {
      final (question, answer) = example;
      final prompt = mnemonicPrompt(question: question, answer: answer);
      var previousPosition = -1;

      for (final section in _sections) {
        final position = prompt.indexOf(section);

        expect(position, greaterThan(previousPosition));
        previousPosition = position;
      }
    });
  });

  test('mnemonicTitle property shows short questions whole', () {
    forAll((random) => anyTextOf(random, maximum: _shownLimit), (question) {
      expect(mnemonicTitle('  $question  '), '$_titleStart${question.trim()}');
    });
  });

  test('mnemonicTitle property cuts long questions at the limit', () {
    forAll((random) => textFrom(random, 'abc de', _shownLimit + 1, 200), (
      question,
    ) {
      final trimmed = question.trim();
      final title = mnemonicTitle(question);

      if (trimmed.length <= _shownLimit) {
        expect(title, '$_titleStart$trimmed');
        return;
      }

      final shown = title.substring(_titleStart.length, title.length - 1);

      expect(title, startsWith(_titleStart));
      expect(title, endsWith('…'));
      expect(shown.length, lessThanOrEqualTo(_shownLimit));
      expect(trimmed, startsWith(shown));
    });
  });
}
