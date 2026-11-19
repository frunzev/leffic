import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'even_line_breaks.dart';

const double _widthPrecision = 1;

class BalancedText extends StatelessWidget {
  const BalancedText(
    this.span, {
    required this.style,
    this.textAlign = TextAlign.start,
    super.key,
  });

  final InlineSpan span;
  final TextStyle style;
  final TextAlign textAlign;

  Widget _buildEvenLines(BuildContext context, BoxConstraints constraints) {
    final plainSpan = span as TextSpan;
    final effectiveStyle = DefaultTextStyle.of(context).style
        .merge(style)
        .merge(plainSpan.style);
    final evenText = evenlyBrokenText(
      text: plainSpan.text ?? '',
      style: effectiveStyle,
      maximumWidth: constraints.maxWidth,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    final evenSpan = TextSpan(text: evenText, style: plainSpan.style);

    return Text.rich(evenSpan, style: style, textAlign: textAlign);
  }

  bool get _isPlainText {
    final textSpan = span;

    return textSpan is TextSpan && textSpan.children == null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isPlainText) {
      return LayoutBuilder(builder: _buildEvenLines);
    }

    return _NarrowestWidth(
      child: Text.rich(span, style: style, textAlign: textAlign),
    );
  }
}

class _NarrowestWidth extends SingleChildRenderObjectWidget {
  const _NarrowestWidth({required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderNarrowestWidth();
  }
}

class _RenderNarrowestWidth extends RenderProxyBox {
  double _heightAt(double width) {
    final paragraph = child!;

    return paragraph.getDryLayout(BoxConstraints(maxWidth: width)).height;
  }

  double _narrowestWidthOf(double maximumWidth) {
    if (maximumWidth.isInfinite) {
      return maximumWidth;
    }

    final fullWidthHeight = _heightAt(maximumWidth);
    final oneLineHeight = _heightAt(double.infinity);
    final lineCount = (fullWidthHeight / oneLineHeight).round();

    if (lineCount > chromiumBalancedLineLimit) {
      return maximumWidth;
    }

    var tooNarrowWidth = 0.0;
    var wideEnoughWidth = maximumWidth;

    while (wideEnoughWidth - tooNarrowWidth > _widthPrecision) {
      final middleWidth = (tooNarrowWidth + wideEnoughWidth) / 2;
      final isLineCountKept = _heightAt(middleWidth) <= fullWidthHeight;

      if (isLineCountKept) {
        wideEnoughWidth = middleWidth;
      } else {
        tooNarrowWidth = middleWidth;
      }
    }

    return wideEnoughWidth;
  }

  BoxConstraints _narrowestConstraints(BoxConstraints constraints) {
    final narrowestWidth = _narrowestWidthOf(constraints.maxWidth);

    return BoxConstraints(
      maxWidth: narrowestWidth,
      maxHeight: constraints.maxHeight,
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final paragraph = child!;
    final paragraphSize = paragraph.getDryLayout(
      _narrowestConstraints(constraints),
    );

    return constraints.constrain(paragraphSize);
  }

  @override
  void performLayout() {
    final paragraph = child!;

    paragraph.layout(_narrowestConstraints(constraints), parentUsesSize: true);
    size = constraints.constrain(paragraph.size);
  }
}
