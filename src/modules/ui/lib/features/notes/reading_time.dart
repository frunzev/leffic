import 'dart:math';

const int _wordsPerMinute = 200;
const int _shortestReadingMinutes = 1;
const String _wordlessNoteLabel = 'Generated note';
final RegExp _htmlTag = RegExp(r'<[^>]*>');
final RegExp _whitespace = RegExp(r'\s+');

int countWordsInHtml(String html) {
  final plainText = html.replaceAll(_htmlTag, ' ');
  var wordCount = 0;

  for (final word in plainText.split(_whitespace)) {
    if (word.isNotEmpty) {
      wordCount++;
    }
  }

  return wordCount;
}

int readingMinutesFor(int wordCount) {
  final roundedMinutes = (wordCount / _wordsPerMinute).round();

  return max(_shortestReadingMinutes, roundedMinutes);
}

String readingTimeLabel(String html) {
  final wordCount = countWordsInHtml(html);

  if (wordCount == 0) {
    return _wordlessNoteLabel;
  }

  return '${readingMinutesFor(wordCount)} min read';
}
