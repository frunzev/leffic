import 'package:flutter/material.dart';

import '../design/design_metrics.dart';
import '../design/hint_tip.dart';
import '../design/segmented_control.dart';
import 'amount_choice.dart';
import 'check_label.dart';
import 'custom_amount_field.dart';
import 'generation_choices.dart';

const double _typeNameWidth = 176;
const double _rowMinimumHeight = 32;

String _amountLabelOf(AmountMode mode) => mode.label;

class _TypeName extends StatelessWidget {
  const _TypeName({
    required this.option,
    required this.isChecked,
    required this.onToggle,
  });

  final StudyUnitTypeOption option;
  final bool isChecked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final explanation = option.explanation;

    return SizedBox(
      width: _typeNameWidth,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _rowMinimumHeight),
        child: Row(
          spacing: Spacing.step2,
          children: [
            Flexible(
              child: CheckLabel(
                label: option.label,
                isChecked: isChecked,
                onToggle: onToggle,
              ),
            ),
            if (explanation != null)
              HintTip(
                text: explanation.answer,
                semanticLabel: explanation.question,
              ),
          ],
        ),
      ),
    );
  }
}

class TypeRow extends StatelessWidget {
  const TypeRow({
    required this.option,
    required this.choice,
    required this.onChanged,
    super.key,
  });

  final StudyUnitTypeOption option;
  final GeneratedSetChoice choice;
  final ValueChanged<GeneratedSetChoice> onChanged;

  AmountChoice get _amountChoice => choice.amountChoiceOf(option.id);

  void _toggleType() {
    onChanged(choice.withTypeToggled(option.id));
  }

  void _changeAmount(AmountChoice amountChoice) {
    onChanged(
      choice.withAmountChoice(typeId: option.id, amountChoice: amountChoice),
    );
  }

  void _selectMode(AmountMode mode) {
    _changeAmount(_amountChoice.withMode(mode));
  }

  void _typeAmount(int? amount) {
    _changeAmount(_amountChoice.withCustomAmount(amount));
  }

  @override
  Widget build(BuildContext context) {
    final isTypeChosen = choice.chosenTypeIds.contains(option.id);
    final amountChoice = _amountChoice;
    final isCustomShown =
        isTypeChosen && amountChoice.mode == AmountMode.custom;

    return Wrap(
      spacing: Spacing.step4,
      runSpacing: Spacing.step2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _TypeName(
          option: option,
          isChecked: isTypeChosen,
          onToggle: _toggleType,
        ),
        if (isTypeChosen)
          SegmentedControl<AmountMode>(
            choices: AmountMode.values,
            labelOf: _amountLabelOf,
            selected: amountChoice.mode,
            onSelected: _selectMode,
          ),
        if (isCustomShown)
          CustomAmountField(
            amount: amountChoice.customAmount,
            onChanged: _typeAmount,
          ),
      ],
    );
  }
}
