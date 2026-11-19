import 'flashcard_faces.dart';

const String _lineBreak = '\n';

class FaceFields {
  const FaceFields({
    required this.firstLabel,
    required this.firstText,
    required this.secondLabel,
    required this.secondText,
  });

  final String firstLabel;
  final String firstText;
  final String secondLabel;
  final String secondText;
}

FaceFields editableFieldsOf(FlashcardFace face) {
  return switch (face) {
    BasicFace(:final front, :final back) => FaceFields(
      firstLabel: 'Front',
      firstText: front,
      secondLabel: 'Back',
      secondText: back,
    ),
    ClozeFace(:final text, :final hiddenParts) => FaceFields(
      firstLabel: 'Sentence',
      firstText: text,
      secondLabel: 'Hidden parts, one per line',
      secondText: hiddenParts.join(_lineBreak),
    ),
    ListFace(:final question, :final items) => FaceFields(
      firstLabel: 'Question',
      firstText: question,
      secondLabel: 'Items, one per line',
      secondText: items.join(_lineBreak),
    ),
    FeynmanFace(:final prompt, :final referenceExplanation) => FaceFields(
      firstLabel: 'Explain this',
      firstText: prompt,
      secondLabel: 'Reference explanation',
      secondText: referenceExplanation,
    ),
  };
}

FlashcardFace faceEditedWith(
  FlashcardFace original, {
  required String firstText,
  required String secondText,
}) {
  return switch (original) {
    BasicFace() => BasicFace(front: firstText, back: secondText),
    ClozeFace() => ClozeFace(
      text: firstText,
      hiddenParts: nonBlankLines(secondText),
    ),
    ListFace() => ListFace(
      question: firstText,
      items: nonBlankLines(secondText),
    ),
    FeynmanFace() => FeynmanFace(
      prompt: firstText,
      referenceExplanation: secondText,
    ),
  };
}

List<String> nonBlankLines(String text) {
  final lines = <String>[];

  for (final line in text.split(_lineBreak)) {
    final trimmedLine = line.trim();

    if (trimmedLine.isNotEmpty) {
      lines.add(trimmedLine);
    }
  }

  return lines;
}
