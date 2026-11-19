import 'package:flutter/material.dart';

import '../../shared/design/balanced_text.dart';
import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import 'cloze_pieces.dart';

const String _blankCharacter = '\u00A0';
const double _blankUnderlineWidth = 2;
const Color _transparent = Color(0x00000000);

enum ClozeMarkLook { blank, revealed }

class ClozeText extends StatelessWidget {
  const ClozeText({
    required this.text,
    required this.hiddenParts,
    required this.look,
    required this.style,
    super.key,
  });

  final String text;
  final List<String> hiddenParts;
  final ClozeMarkLook look;
  final TextStyle style;

  InlineSpan _spanOf(ClozePiece piece) {
    if (!piece.isHidden) {
      return TextSpan(text: piece.text);
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: ClozeMark(hiddenPart: piece.text, look: look, textStyle: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];

    for (final piece in clozePieces(text: text, hiddenParts: hiddenParts)) {
      spans.add(_spanOf(piece));
    }

    return BalancedText(
      TextSpan(children: spans),
      style: style,
      textAlign: TextAlign.center,
    );
  }
}

class ClozeMark extends StatelessWidget {
  const ClozeMark({
    required this.hiddenPart,
    required this.look,
    required this.textStyle,
    super.key,
  });

  final String hiddenPart;
  final ClozeMarkLook look;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);
    final (shownText, ink, decoration) = switch (look) {
      ClozeMarkLook.blank => (
        _blankCharacter * hiddenPart.length,
        _transparent,
        BoxDecoration(
          color: colors.surfaceTertiary,
          border: Border(
            bottom: BorderSide(
              color: colors.lineHover,
              width: _blankUnderlineWidth,
            ),
          ),
        ),
      ),
      ClozeMarkLook.revealed => (
        hiddenPart,
        colors.brandStrong,
        BoxDecoration(color: colors.brandSurface),
      ),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.extraSmall),
      child: DecoratedBox(
        decoration: decoration,
        child: Text(
          shownText,
          style: textStyle.copyWith(color: ink, height: kTextHeightNone),
        ),
      ),
    );
  }
}
