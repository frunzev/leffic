import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/even_line_breaks.dart';

import '../../support/property.dart';
import '../../support/rendered_text.dart';

const TextStyle _evenStyle = TextStyle(fontSize: 10, letterSpacing: 0);
const String _dashes = '-–—';
const double _widthSlack = 0.01;

typedef _EvenExample = ({String text, double width});

String _textOf(Random random) {
  final wordCount = integerBetween(random, 1, 14);
  final words = <String>[];

  for (var index = 0; index < wordCount; index++) {
    final word = wordOf(random, maximum: 7);
    final isDashed = random.nextInt(5) == 0;

    words.add(isDashed ? '$word${oneOf(random, _dashes.split(''))}' : word);
  }

  return words.join(' ');
}

List<_EvenExample> _evenExamples() {
  return examplesOf(
    (random) => (
      text: _textOf(random),
      width: integerBetween(random, 80, 400).toDouble(),
    ),
    runs: 60,
  );
}

TextPainter _laidOut(String text, double width) {
  return TextPainter(
    text: TextSpan(text: text, style: _evenStyle),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width);
}

String _evenTextOf(_EvenExample example) {
  return evenlyBrokenText(
    text: example.text,
    style: _evenStyle,
    maximumWidth: example.width,
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.noScaling,
  );
}

void main() {
  test('evenlyBrokenText property only turns break chances into lines', () {
    for (final example in _evenExamples()) {
      expect(withoutLineBreaks(_evenTextOf(example)), example.text);
    }
  });

  test('evenlyBrokenText property keeps the line count of plain wrapping', () {
    for (final example in _evenExamples()) {
      final plain = _laidOut(example.text, example.width);
      final even = _laidOut(_evenTextOf(example), example.width);
      final plainLines = plain.computeLineMetrics().length;
      final evenLines = even.computeLineMetrics().length;

      if (plainLines <= 6) {
        expect(evenLines, plainLines);
      }

      plain.dispose();
      even.dispose();
    }
  });

  test('evenlyBrokenText property never makes a line wider than allowed', () {
    for (final example in _evenExamples()) {
      final evenText = _evenTextOf(example);

      if (!evenText.contains('\n')) {
        continue;
      }

      final even = _laidOut(evenText, double.infinity);

      for (final line in even.computeLineMetrics()) {
        expect(line.width, lessThanOrEqualTo(example.width + _widthSlack));
      }

      even.dispose();
    }
  });

  test('evenlyBrokenText property leaves text without room as it is', () {
    forAll(_textOf, (text) {
      final unbounded = evenlyBrokenText(
        text: text,
        style: _evenStyle,
        maximumWidth: double.infinity,
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      );

      expect(unbounded, text);
    });
  });
}
