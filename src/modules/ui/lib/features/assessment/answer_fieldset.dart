import 'package:flutter/material.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_shadows.dart';
import '../../shared/design/design_typography.dart';
import '../../shared/design/surface_box.dart';
import 'add_answer_button.dart';
import 'answer_row.dart';

const double _listBorderWidth = 1;

class AnswerFieldset extends StatelessWidget {
  const AnswerFieldset({
    required this.answers,
    required this.correctIndex,
    required this.onMarkCorrect,
    required this.onRemove,
    required this.onAdd,
    required this.onChanged,
    super.key,
  });

  final List<TextEditingController> answers;
  final int correctIndex;
  final ValueChanged<int> onMarkCorrect;
  final ValueChanged<int> onRemove;
  final VoidCallback onAdd;
  final VoidCallback onChanged;

  Widget _legend(DesignColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.step2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        spacing: Spacing.step2,
        children: [
          Text(
            'Answers',
            style: textStyleForSize(TextSizes.small)
                .copyWith(color: colors.ink, fontWeight: FontWeight.w500),
          ),
          Text(
            'Pick the correct one',
            style: textStyleForSize(
              TextSizes.small,
            ).copyWith(color: colors.inkTertiary, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _answerRow(int index) {
    final controller = answers[index];

    return AnswerRow(
      key: ObjectKey(controller),
      controller: controller,
      index: index,
      correctIndex: correctIndex,
      onMarkCorrect: onMarkCorrect,
      onRemove: () => onRemove(index),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);
    final shadows = DesignShadows.of(context);
    final listLook = SurfaceLook(
      fill: colors.surface,
      border: BorderSide(color: colors.lineStrong),
      shadows: shadows.raised,
      edgeHighlight: shadows.edgeHighlight,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _legend(colors),
        SurfaceBox(
          look: listLook,
          borderRadius: Radii.medium,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              Radii.medium - _listBorderWidth,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < answers.length; index++)
                  _answerRow(index),
                AddAnswerButton(onPressed: onAdd),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
