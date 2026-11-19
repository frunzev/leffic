import 'package:flutter/material.dart';

import '../design/choice_marks.dart';
import '../design/design_colors.dart';
import '../design/design_metrics.dart';
import '../design/design_typography.dart';
import 'check_label.dart';
import 'generation_choices.dart';
import 'type_row.dart';

const double _optionsIndent = Spacing.step5;
const double _optionsRuleWidth = 2;
const String _typesLabel = 'Types and how many';

class UnitChoice extends StatelessWidget {
  const UnitChoice({
    required this.name,
    required this.hint,
    required this.isChosen,
    required this.onToggle,
    required this.chosenOptions,
    super.key,
  });

  final String name;
  final String hint;
  final bool isChosen;
  final VoidCallback onToggle;
  final List<Widget> chosenOptions;

  void _toggle(bool isNowChecked) {
    onToggle();
  }

  Widget _head(DesignColors colors) {
    return TappableLabel(
      onTap: onToggle,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        spacing: Spacing.step3,
        children: [
          DesignCheckbox(isChecked: isChosen, onChanged: _toggle),
          Text(
            name,
            style: textStyleForSize(TextSizes.medium)
                .copyWith(color: colors.ink, fontWeight: FontWeight.w600),
          ),
          Flexible(
            child: Text(
              hint,
              style: textStyleForSize(TextSizes.small)
                  .copyWith(color: colors.inkTertiary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _head(DesignColors.of(context)),
        if (isChosen) ...chosenOptions,
      ],
    );
  }
}

class TypeChoiceOptions extends StatelessWidget {
  const TypeChoiceOptions({
    required this.options,
    required this.choice,
    required this.onChanged,
    super.key,
  });

  final List<StudyUnitTypeOption> options;
  final GeneratedSetChoice choice;
  final ValueChanged<GeneratedSetChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: Spacing.step3, left: _optionsIndent),
      child: Container(
        padding: const EdgeInsets.only(left: Spacing.step4),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: colors.line, width: _optionsRuleWidth),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _typesLabel,
              style: textStyleForSize(TextSizes.small)
                  .copyWith(color: colors.inkSecondary),
            ),
            const SizedBox(height: Spacing.step2),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Spacing.step2,
              children: [
                for (final option in options)
                  TypeRow(option: option, choice: choice, onChanged: onChanged),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
