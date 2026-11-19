import '../../shared/api/json_reading.dart';

const String _basicType = 'basic';
const String _clozeType = 'cloze';
const String _listType = 'list';
const String _feynmanType = 'feynman';
const String _itemSeparator = ', ';
const String _hiddenPartsIntroduction = 'The hidden parts are: ';

sealed class FlashcardFace {
  const FlashcardFace();

  factory FlashcardFace.fromContent({
    required String type,
    required JsonObject content,
  }) {
    return switch (type) {
      _basicType => BasicFace.fromContent(content),
      _clozeType => ClozeFace.fromContent(content),
      _listType => ListFace.fromContent(content),
      _feynmanType => FeynmanFace.fromContent(content),
      _ => throw FormatException('Unknown flashcard type "$type"'),
    };
  }

  String get question;

  String get answer;

  bool get isIncomplete => question.trim().isEmpty || answer.trim().isEmpty;

  JsonObject toContent();
}

class BasicFace extends FlashcardFace {
  const BasicFace({required this.front, required this.back});

  factory BasicFace.fromContent(JsonObject content) {
    return BasicFace(
      front: readText(content, 'front'),
      back: readText(content, 'back'),
    );
  }

  final String front;
  final String back;

  @override
  String get question => front;

  @override
  String get answer => back;

  @override
  JsonObject toContent() => {'front': front, 'back': back};
}

class ClozeFace extends FlashcardFace {
  const ClozeFace({required this.text, required this.hiddenParts});

  factory ClozeFace.fromContent(JsonObject content) {
    return ClozeFace(
      text: readText(content, 'text'),
      hiddenParts: readTexts(content, 'hidden_parts'),
    );
  }

  final String text;
  final List<String> hiddenParts;

  @override
  String get question => text;

  @override
  String get answer {
    return '$_hiddenPartsIntroduction${hiddenParts.join(_itemSeparator)}';
  }

  @override
  JsonObject toContent() => {'text': text, 'hidden_parts': hiddenParts};
}

class ListFace extends FlashcardFace {
  const ListFace({required this.question, required this.items});

  factory ListFace.fromContent(JsonObject content) {
    return ListFace(
      question: readText(content, 'question'),
      items: readTexts(content, 'items'),
    );
  }

  @override
  final String question;
  final List<String> items;

  @override
  String get answer => items.join(_itemSeparator);

  @override
  JsonObject toContent() => {'question': question, 'items': items};
}

class FeynmanFace extends FlashcardFace {
  const FeynmanFace({required this.prompt, required this.referenceExplanation});

  factory FeynmanFace.fromContent(JsonObject content) {
    return FeynmanFace(
      prompt: readText(content, 'prompt'),
      referenceExplanation: readText(content, 'reference_explanation'),
    );
  }

  final String prompt;
  final String referenceExplanation;

  @override
  String get question => prompt;

  @override
  String get answer => referenceExplanation;

  @override
  JsonObject toContent() {
    return {'prompt': prompt, 'reference_explanation': referenceExplanation};
  }
}
