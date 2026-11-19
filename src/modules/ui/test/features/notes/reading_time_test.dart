import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/features/notes/reading_time.dart';

import '../../support/property.dart';

const List<String> _tags = ['p', 'b', 'em', 'li', 'h2'];
const List<String> _gaps = ['', ' ', '\n', '\t', '  \n '];
const int _wordsPerMinute = 200;

List<String> _generatedWords(Random random, {int minimum = 0}) {
  final count = integerBetween(random, minimum, 900);
  final words = <String>[];

  for (var index = 0; index < count; index++) {
    words.add(wordOf(random));
  }

  return words;
}

String _markedUp(Random random, List<String> words) {
  final html = StringBuffer(oneOf(random, _gaps));

  for (final word in words) {
    final tag = oneOf(random, _tags);
    final gap = oneOf(random, _gaps);

    html.write('<$tag class="part">$word</$tag>$gap');
  }

  return html.toString();
}

String _bareMarkup(Random random) {
  final emptyTags = List.filled(integerBetween(random, 0, 5), '');

  return _markedUp(random, emptyTags);
}

void main() {
  test('countWordsInHtml property counts every word between the tags', () {
    forAll(
      (random) {
        final words = _generatedWords(random);

        return (words, _markedUp(random, words));
      },
      (example) {
        final (words, html) = example;

        expect(countWordsInHtml(html), words.length);
      },
    );
  });

  test('countWordsInHtml property finds no words in bare markup', () {
    forAll(_bareMarkup, (html) {
      expect(countWordsInHtml(html), 0);
    });
  });

  test('readingMinutesFor property stays near 200 words per minute', () {
    forAll((random) => integerBetween(random, 1, 40000), (wordCount) {
      final minutes = readingMinutesFor(wordCount);
      final exactMinutes = wordCount / _wordsPerMinute;
      final isNearExact = (minutes - exactMinutes).abs() <= 0.5;

      expect(minutes, greaterThanOrEqualTo(1));
      expect(isNearExact || minutes == 1, isTrue);
    });
  });

  test('readingMinutesFor property never drops as words are added', () {
    forAll(
      (random) =>
          (integerBetween(random, 1, 20000), integerBetween(random, 0, 20000)),
      (example) {
        final (wordCount, addedWords) = example;
        final shorter = readingMinutesFor(wordCount);
        final longer = readingMinutesFor(wordCount + addedWords);

        expect(longer, greaterThanOrEqualTo(shorter));
      },
    );
  });

  test('readingTimeLabel property names the minutes of a worded note', () {
    forAll(
      (random) {
        final words = _generatedWords(random, minimum: 1);

        return (words, _markedUp(random, words));
      },
      (example) {
        final (words, html) = example;
        final minutes = readingMinutesFor(words.length);

        expect(readingTimeLabel(html), '$minutes min read');
      },
    );
  });

  test('readingTimeLabel property calls a wordless note generated', () {
    forAll(_bareMarkup, (html) {
      expect(readingTimeLabel(html), 'Generated note');
    });
  });
}
