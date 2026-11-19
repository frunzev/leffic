import 'package:flutter/material.dart';

import '../../shared/design/balanced_text.dart';
import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';
import 'cloze_text.dart';
import 'face_box.dart';
import 'flashcard_faces.dart';

const String _listMarker = '•\u00A0';

Widget _balancedParagraph(String text, TextStyle style) {
  return BalancedText(
    TextSpan(text: text),
    style: style,
    textAlign: TextAlign.center,
  );
}

class FlashcardPromptView extends StatelessWidget {
  const FlashcardPromptView({required this.face, super.key});

  final FlashcardFace face;

  Widget _listPrompt(String question, int itemCount, DesignColors colors) {
    final hintStyle = textStyleForSize(TextSizes.small)
        .copyWith(color: colors.inkTertiary, height: baseLineHeight);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _balancedParagraph(question, faceTextStyle(FaceSide.prompt, colors)),
        _balancedParagraph(
          'Name $itemCount items, then check yourself.',
          hintStyle,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);
    final style = faceTextStyle(FaceSide.prompt, colors);
    final content = switch (face) {
      ClozeFace(:final text, :final hiddenParts) => ClozeText(
        text: text,
        hiddenParts: hiddenParts,
        look: ClozeMarkLook.blank,
        style: style,
      ),
      ListFace(:final question, :final items) => _listPrompt(
        question,
        items.length,
        colors,
      ),
      BasicFace() || FeynmanFace() => _balancedParagraph(face.question, style),
    };

    return FlashcardFaceBox(side: FaceSide.prompt, child: content);
  }
}

class FlashcardAnswerView extends StatelessWidget {
  const FlashcardAnswerView({required this.face, super.key});

  final FlashcardFace face;

  Widget _listItem(String item, TextStyle itemStyle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: Spacing.step5,
          child: Text(
            _listMarker,
            textAlign: TextAlign.right,
            softWrap: false,
            style: itemStyle,
          ),
        ),
        Flexible(
          child: BalancedText(TextSpan(text: item), style: itemStyle),
        ),
      ],
    );
  }

  Widget _listAnswer(List<String> items, DesignColors colors) {
    final itemStyle = textStyleForSize(TextSizes.medium)
        .copyWith(color: colors.ink, height: baseLineHeight);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.step2,
      children: [for (final item in items) _listItem(item, itemStyle)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);
    final style = faceTextStyle(FaceSide.answer, colors);
    final content = switch (face) {
      ClozeFace(:final text, :final hiddenParts) => ClozeText(
        text: text,
        hiddenParts: hiddenParts,
        look: ClozeMarkLook.revealed,
        style: style,
      ),
      ListFace(:final items) => _listAnswer(items, colors),
      BasicFace() || FeynmanFace() => _balancedParagraph(face.answer, style),
    };

    return FlashcardFaceBox(side: FaceSide.answer, child: content);
  }
}
