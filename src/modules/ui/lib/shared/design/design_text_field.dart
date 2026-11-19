import 'dart:math';

import 'package:flutter/material.dart';

import 'design_colors.dart';
import 'design_metrics.dart';
import 'design_typography.dart';
import 'input_frame.dart';

export 'input_frame.dart' show FieldValidity;

const double _inputBorderWidth = 1;
const double _textAreaPadding = Spacing.step3;
const double _textAreaMinimumHeight = 132;
const int _textAreaDefaultRows = 3;
const double _inputLineHeight = TextSizes.medium * baseLineHeight;

const double _compactHeight = 32;

enum TextFieldSize {
  small(height: _compactHeight, horizontalPadding: Spacing.step3),
  regular(height: ControlHeights.regular, horizontalPadding: Spacing.step3),
  large(height: ControlHeights.large, horizontalPadding: Spacing.step4);

  const TextFieldSize({required this.height, required this.horizontalPadding});

  final double height;
  final double horizontalPadding;
}

enum TextVisibility { plain, obscured }

enum InitialFocus { unfocused, focused }

enum TextEditability { editable, readOnly }

TextStyle _inputTextStyle(BuildContext context, Color color) {
  return DefaultTextStyle.of(context).style.merge(
    textStyleForSize(TextSizes.medium)
        .copyWith(color: color, height: baseLineHeight),
  );
}

InputDecoration _inputDecoration(
  BuildContext context,
  String? placeholder,
  EdgeInsets padding,
) {
  final colors = DesignColors.of(context);

  return InputDecoration(
    isCollapsed: true,
    border: InputBorder.none,
    hintText: placeholder,
    hintStyle: _inputTextStyle(context, colors.inkTertiary),
    contentPadding: padding,
  );
}

class DesignTextField extends StatelessWidget {
  const DesignTextField({
    required this.controller,
    this.placeholder,
    this.onChanged,
    this.onSubmitted,
    this.size = TextFieldSize.regular,
    this.validity = FieldValidity.valid,
    this.visibility = TextVisibility.plain,
    this.initialFocus = InitialFocus.unfocused,
    this.editability = TextEditability.editable,
    this.keyboardType,
    this.textInputAction,
    super.key,
  });

  final TextEditingController controller;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextFieldSize size;
  final FieldValidity validity;
  final TextVisibility visibility;
  final InitialFocus initialFocus;
  final TextEditability editability;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  Widget _buildField(BuildContext context, FocusNode focusNode) {
    final verticalPadding =
        (size.height - 2 * _inputBorderWidth - _inputLineHeight) / 2;
    final padding = EdgeInsets.symmetric(
      horizontal: size.horizontalPadding,
      vertical: verticalPadding,
    );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: initialFocus == InitialFocus.focused,
      obscureText: visibility == TextVisibility.obscured,
      readOnly: editability == TextEditability.readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: _inputTextStyle(context, DesignColors.of(context).ink),
      cursorColor: DesignColors.of(context).ink,
      decoration: _inputDecoration(context, placeholder, padding),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InputFrame(
      validity: validity,
      height: size.height,
      builder: _buildField,
    );
  }
}

class DesignTextArea extends StatelessWidget {
  const DesignTextArea({
    required this.controller,
    this.placeholder,
    this.onChanged,
    this.rows = _textAreaDefaultRows,
    this.minimumHeight = _textAreaMinimumHeight,
    this.validity = FieldValidity.valid,
    this.initialFocus = InitialFocus.unfocused,
    super.key,
  });

  final TextEditingController controller;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final int rows;
  final double minimumHeight;
  final FieldValidity validity;
  final InitialFocus initialFocus;

  Widget _buildField(BuildContext context, FocusNode focusNode) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: initialFocus == InitialFocus.focused,
      expands: true,
      maxLines: null,
      textAlignVertical: TextAlignVertical.top,
      onChanged: onChanged,
      style: _inputTextStyle(context, DesignColors.of(context).ink),
      cursorColor: DesignColors.of(context).ink,
      decoration: _inputDecoration(
        context,
        placeholder,
        const EdgeInsets.all(_textAreaPadding),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rowsHeight =
        rows * _inputLineHeight + 2 * _textAreaPadding + 2 * _inputBorderWidth;

    return InputFrame(
      validity: validity,
      height: max(minimumHeight, rowsHeight),
      builder: _buildField,
    );
  }
}
