import 'package:flutter/material.dart';

import '../design/design_text_field.dart';

const double _fieldWidth = 72;
const int _smallestAmount = 1;

int? _amountOf(String typed) {
  final amount = int.tryParse(typed.trim());

  if (amount == null || amount < _smallestAmount) {
    return null;
  }

  return amount;
}

String _textOf(int? amount) {
  if (amount == null) {
    return '';
  }

  return '$amount';
}

class CustomAmountField extends StatefulWidget {
  const CustomAmountField({
    required this.amount,
    required this.onChanged,
    super.key,
  });

  final int? amount;
  final ValueChanged<int?> onChanged;

  @override
  State<CustomAmountField> createState() => _CustomAmountFieldState();
}

class _CustomAmountFieldState extends State<CustomAmountField> {
  late final TextEditingController _typed = TextEditingController(
    text: _textOf(widget.amount),
  );

  @override
  void didUpdateWidget(CustomAmountField oldWidget) {
    super.didUpdateWidget(oldWidget);

    final isShowingAnotherAmount = _amountOf(_typed.text) != widget.amount;

    if (isShowingAnotherAmount) {
      _typed.text = _textOf(widget.amount);
    }
  }

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  void _report(String typed) {
    widget.onChanged(_amountOf(typed));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _fieldWidth,
      child: DesignTextField(
        controller: _typed,
        keyboardType: TextInputType.number,
        onChanged: _report,
        size: TextFieldSize.small,
      ),
    );
  }
}
