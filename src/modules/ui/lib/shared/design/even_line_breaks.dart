import 'package:flutter/painting.dart';

const int chromiumBalancedLineLimit = 6;
const String _space = ' ';
const String _lineBreak = '\n';
const String _dashes = '-–—';

typedef _BreakChance = ({int lineEnd, int nextLineStart});
typedef _LineWidthOf = double Function(int start, int end);

List<_BreakChance> _breakChancesOf(String text) {
  final chances = <_BreakChance>[];

  for (var index = 0; index < text.length; index++) {
    final character = text[index];

    final nextCharacter = index + 1 < text.length ? text[index + 1] : _space;
    final isDashInsideWord =
        _dashes.contains(character) && nextCharacter != _space;

    if (character == _space) {
      chances.add((lineEnd: index, nextLineStart: index + 1));
    } else if (isDashInsideWord) {
      chances.add((lineEnd: index + 1, nextLineStart: index + 1));
    }
  }

  return chances;
}

List<_BreakChance>? _leastSlackBreaks({
  required List<_BreakChance> chances,
  required int lineCount,
  required int textLength,
  required double maximumWidth,
  required _LineWidthOf lineWidthOf,
}) {
  final lineStarts = [0, for (final chance in chances) chance.nextLineStart];
  final lineEnds = [for (final chance in chances) chance.lineEnd, textLength];
  final endCount = lineEnds.length;
  final costs = List.generate(lineCount, (_) => List.filled(endCount, -1.0));
  final previous = List.generate(lineCount, (_) => List.filled(endCount, -1));

  for (var line = 0; line < lineCount; line++) {
    for (var end = 0; end < endCount; end++) {
      final firstStart = line == 0 ? 0 : 1;
      final lastStart = line == 0 ? 0 : end;

      for (var start = firstStart; start <= lastStart; start++) {
        final lineStart = lineStarts[start];
        final lineEnd = lineEnds[end];
        final priorCost = line == 0 ? 0.0 : costs[line - 1][start - 1];

        if (priorCost < 0 || lineEnd <= lineStart) {
          continue;
        }

        final width = lineWidthOf(lineStart, lineEnd);

        if (width > maximumWidth) {
          continue;
        }

        final slack = maximumWidth - width;
        final cost = priorCost + slack * slack;
        final bestCost = costs[line][end];

        if (bestCost < 0 || cost <= bestCost) {
          costs[line][end] = cost;
          previous[line][end] = start - 1;
        }
      }
    }
  }

  if (costs[lineCount - 1][endCount - 1] < 0) {
    return null;
  }

  final chosen = <_BreakChance>[];
  var chance = previous[lineCount - 1][endCount - 1];

  for (var line = lineCount - 1; line > 0; line--) {
    chosen.insert(0, chances[chance]);
    chance = previous[line - 1][chance];
  }

  return chosen;
}

String _textWithBreaks(String text, List<_BreakChance> breaks) {
  final brokenText = StringBuffer();
  var copiedUpTo = 0;

  for (final chosenBreak in breaks) {
    brokenText.write(text.substring(copiedUpTo, chosenBreak.nextLineStart));
    brokenText.write(_lineBreak);
    copiedUpTo = chosenBreak.nextLineStart;
  }

  brokenText.write(text.substring(copiedUpTo));

  return brokenText.toString();
}

String evenlyBrokenText({
  required String text,
  required TextStyle style,
  required double maximumWidth,
  required TextDirection textDirection,
  required TextScaler textScaler,
}) {
  if (maximumWidth.isInfinite || text.contains(_lineBreak)) {
    return text;
  }

  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: textDirection,
    textScaler: textScaler,
  );

  painter.layout(maxWidth: maximumWidth);
  final lineCount = painter.computeLineMetrics().length;

  painter.layout();
  final caretOffsets = [
    for (var index = 0; index <= text.length; index++)
      painter.getOffsetForCaret(TextPosition(offset: index), Rect.zero).dx,
  ];
  painter.dispose();

  if (lineCount < 2 || lineCount > chromiumBalancedLineLimit) {
    return text;
  }

  final breaks = _leastSlackBreaks(
    chances: _breakChancesOf(text),
    lineCount: lineCount,
    textLength: text.length,
    maximumWidth: maximumWidth,
    lineWidthOf: (start, end) => caretOffsets[end] - caretOffsets[start],
  );

  if (breaks == null) {
    return text;
  }

  return _textWithBreaks(text, breaks);
}
