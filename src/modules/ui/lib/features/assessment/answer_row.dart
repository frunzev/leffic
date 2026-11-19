import 'package:flutter/material.dart';

import '../../shared/design/bare_icon_button.dart';
import '../../shared/design/choice_marks.dart';
import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';
import '../../shared/design/icons/design_icons.dart';

const double _rowMinimumHeight = 48;
const double _answerFieldHeight = 44;
const double _removeSide = 32;
const double _focusEdgeWidth = 2;
const double _answerLineHeight = TextSizes.medium * baseLineHeight;
const EdgeInsets _rowPadding = EdgeInsets.only(
  left: Spacing.step4,
  right: Spacing.step2,
);
const EdgeInsets _answerTextPadding = EdgeInsets.symmetric(
  vertical: (_answerFieldHeight - _answerLineHeight) / 2,
);

Color? answerRowFillOf({
  required bool isCorrect,
  required DesignColors colors,
}) {
  if (isCorrect) {
    return colors.brandSurface;
  }

  return null;
}

class FocusEdge extends StatelessWidget {
  const FocusEdge({required this.color, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _focusEdgeWidth,
      child: ColoredBox(color: color),
    );
  }
}

class AnswerRemoveButton extends StatelessWidget {
  const AnswerRemoveButton({
    required this.semanticLabel,
    required this.onPressed,
    super.key,
  });

  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return BareIconButton(
      icon: DesignIcons.closePlain,
      semanticLabel: semanticLabel,
      side: _removeSide,
      hoverFill: colors.dangerSurface,
      hoverInk: colors.danger,
      onPressed: onPressed,
    );
  }
}

class AnswerRow extends StatefulWidget {
  const AnswerRow({
    required this.controller,
    required this.index,
    required this.correctIndex,
    required this.onMarkCorrect,
    required this.onRemove,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final int index;
  final int correctIndex;
  final ValueChanged<int> onMarkCorrect;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  bool get isCorrect => index == correctIndex;

  @override
  State<AnswerRow> createState() => _AnswerRowState();
}

class _AnswerRowState extends State<AnswerRow> {
  bool _hasFocusWithin = false;

  void _showFocusWithin(bool hasFocus) {
    setState(() => _hasFocusWithin = hasFocus);
  }

  Widget _answerField(DesignColors colors, int number) {
    final textStyle = DefaultTextStyle.of(context).style.merge(
      textStyleForSize(TextSizes.medium)
          .copyWith(color: colors.ink, height: baseLineHeight),
    );

    return SizedBox(
      height: _answerFieldHeight,
      child: Semantics(
        label: 'Answer $number',
        child: TextField(
          controller: widget.controller,
          onChanged: (text) => widget.onChanged(),
          style: textStyle,
          cursorColor: colors.ink,
          decoration: const InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            contentPadding: _answerTextPadding,
          ),
        ),
      ),
    );
  }

  Widget _content(DesignColors colors) {
    final number = widget.index + 1;

    return Padding(
      padding: _rowPadding,
      child: Row(
        spacing: Spacing.step3,
        children: [
          Semantics(
            label: 'Mark answer $number as the correct answer',
            child: DesignRadio<int>(
              value: widget.index,
              groupValue: widget.correctIndex,
              onChanged: widget.onMarkCorrect,
            ),
          ),
          Expanded(child: _answerField(colors, number)),
          if (widget.isCorrect)
            Text(
              'Correct',
              style: textStyleForSize(TextSizes.extraSmall).copyWith(
                color: colors.brandStrong,
                fontWeight: FontWeight.w600,
              ),
            ),
          AnswerRemoveButton(
            semanticLabel: 'Remove answer $number',
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: _showFocusWithin,
      child: Container(
        constraints: const BoxConstraints(minHeight: _rowMinimumHeight),
        decoration: BoxDecoration(
          color: answerRowFillOf(isCorrect: widget.isCorrect, colors: colors),
          border: Border(bottom: BorderSide(color: colors.line)),
        ),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            _content(colors),
            if (_hasFocusWithin)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: FocusEdge(color: colors.brand),
              ),
          ],
        ),
      ),
    );
  }
}
