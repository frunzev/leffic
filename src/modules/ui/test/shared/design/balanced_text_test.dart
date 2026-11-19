import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leffic/shared/design/balanced_text.dart';

import '../../support/hosting.dart';
import '../../support/property.dart';
import '../../support/rendered_text.dart';

const TextStyle _paragraphStyle = TextStyle(
  fontSize: 20,
  height: 1.5,
  letterSpacing: 0,
);
const int _chromiumBalancedLineLimit = 6;

const int _bruteForceLineLimit = 3;
const double _slackTolerance = 1e-6;

typedef _ParagraphExample = ({String sentence, double width});

String _sentenceOf(Random random) {
  final wordCount = integerBetween(random, 1, 40);
  final words = <String>[];

  for (var index = 0; index < wordCount; index++) {
    words.add(wordOf(random, maximum: 8));
  }

  return words.join(' ');
}

List<_ParagraphExample> _paragraphExamples() {
  return examplesOf(
    (random) => (
      sentence: _sentenceOf(random),
      width: integerBetween(random, 200, 700).toDouble(),
    ),
    runs: 24,
  );
}

List<_ParagraphExample> _shortParagraphExamples() {
  return examplesOf((random) {
    final wordCount = integerBetween(random, 3, 12);
    final words = <String>[];

    for (var index = 0; index < wordCount; index++) {
      words.add(wordOf(random, maximum: 8));
    }

    return (
      sentence: words.join(' '),
      width: integerBetween(random, 200, 700).toDouble(),
    );
  }, runs: 24);
}

double _widthOfWords(List<String> words) {
  final characterCount = words.join(' ').length;

  return characterCount * (_paragraphStyle.fontSize ?? 0);
}

double _squaredSlackOf(List<double> lineWidths, double width) {
  var squaredSlack = 0.0;

  for (final lineWidth in lineWidths) {
    final slack = width - lineWidth;

    squaredSlack += slack * slack;
  }

  return squaredSlack;
}

double _leastSquaredSlackOf(List<String> words, int lineCount, double width) {
  var leastSquaredSlack = double.infinity;

  for (final lineWidths in _lineWidthSplits(words, lineCount, width)) {
    final squaredSlack = _squaredSlackOf(lineWidths, width);

    if (squaredSlack < leastSquaredSlack) {
      leastSquaredSlack = squaredSlack;
    }
  }

  return leastSquaredSlack;
}

List<List<double>> _lineWidthSplits(
  List<String> words,
  int lineCount,
  double width,
) {
  final wholeWidth = _widthOfWords(words);

  if (lineCount == 1) {
    return wholeWidth <= width
        ? [
            [wholeWidth],
          ]
        : [];
  }

  final splits = <List<double>>[];

  for (var cut = 1; cut <= words.length - lineCount + 1; cut++) {
    final firstWidth = _widthOfWords(words.sublist(0, cut));

    if (firstWidth > width) {
      break;
    }

    final rest = words.sublist(cut);

    for (final restWidths in _lineWidthSplits(rest, lineCount - 1, width)) {
      splits.add([firstWidth, ...restWidths]);
    }
  }

  return splits;
}

List<double> _lineWidthsAt(InlineSpan renderedText, double width) {
  final painter = TextPainter(
    text: renderedText,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width);
  final lineWidths = [
    for (final line in painter.computeLineMetrics()) line.width,
  ];

  painter.dispose();

  return lineWidths;
}

int _lineCountAt(InlineSpan renderedText, double width) {
  final painter = TextPainter(
    text: renderedText,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width);
  final lineCount = painter.computeLineMetrics().length;

  painter.dispose();

  return lineCount;
}

InlineSpan _renderedTextOf(WidgetTester tester) {
  return tester.widget<RichText>(find.byType(RichText)).text;
}

Future<double> _balancedWidthOf(
  WidgetTester tester,
  _ParagraphExample example,
) async {
  await tester.pumpWidget(
    hostedPlainly(
      Center(
        child: SizedBox(
          width: example.width,
          child: Center(
            child: BalancedText(
              TextSpan(text: example.sentence),
              style: _paragraphStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ),
  );

  return tester.getSize(find.byType(RichText)).width;
}

void main() {
  testWidgets('BalancedText property keeps the lines of the full width', (
    tester,
  ) async {
    for (final example in _paragraphExamples()) {
      final balancedWidth = await _balancedWidthOf(tester, example);
      final renderedText = _renderedTextOf(tester);

      expect(balancedWidth, lessThanOrEqualTo(example.width));
      expect(
        _lineCountAt(renderedText, balancedWidth),
        _lineCountAt(renderedText, example.width),
      );
    }
  });

  testWidgets('BalancedText property leaves the least squared slack', (
    tester,
  ) async {
    for (final example in _shortParagraphExamples()) {
      final balancedWidth = await _balancedWidthOf(tester, example);
      final renderedText = _renderedTextOf(tester);
      final words = example.sentence.split(' ');
      final lineCount = _lineCountAt(renderedText, example.width);

      if (lineCount < 2 || lineCount > _bruteForceLineLimit) {
        continue;
      }

      final leastSquaredSlack = _leastSquaredSlackOf(
        words,
        lineCount,
        example.width,
      );
      final renderedSquaredSlack = _squaredSlackOf(
        _lineWidthsAt(renderedText, balancedWidth),
        example.width,
      );

      expect(_lineCountAt(renderedText, balancedWidth), lineCount);
      expect(renderedSquaredSlack, closeTo(leastSquaredSlack, _slackTolerance));
    }
  });

  testWidgets('BalancedText property leaves over six lines as they wrap', (
    tester,
  ) async {
    for (final example in _paragraphExamples()) {
      final balancedWidth = await _balancedWidthOf(tester, example);
      final fullWidthLines = _lineCountAt(
        _renderedTextOf(tester),
        example.width,
      );

      if (fullWidthLines <= _chromiumBalancedLineLimit) {
        continue;
      }

      expect(balancedWidth, example.width);
    }
  });

  testWidgets('BalancedText property paints the span in the given style', (
    tester,
  ) async {
    for (final example in _paragraphExamples()) {
      await _balancedWidthOf(tester, example);

      final paragraph = tester.widget<RichText>(find.byType(RichText));

      expect(withoutLineBreaks(paragraph.text.toPlainText()), example.sentence);
      expect(paragraph.textAlign, TextAlign.center);
      expect(paragraph.text.style?.fontSize, _paragraphStyle.fontSize);
      expect(paragraph.text.style?.height, _paragraphStyle.height);
    }
  });
}
