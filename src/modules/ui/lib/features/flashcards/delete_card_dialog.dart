import 'package:flutter/material.dart';

import '../../shared/design/button_look.dart';
import '../../shared/design/design_button.dart';
import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_modal.dart';
import '../../shared/design/design_typography.dart';
import '../../shared/design/icons/design_icon.dart';
import '../../shared/design/icons/design_icons.dart';
import '../../shared/design/inset_block.dart';

const double _subjectEdgeWidth = 2;
const EdgeInsets _blockPadding = EdgeInsets.symmetric(
  vertical: Spacing.step3,
  horizontal: Spacing.step4,
);

Future<bool> confirmCardDeletion(
  BuildContext context, {
  required String question,
}) async {
  final isConfirmed = await showDesignModal<bool>(
    context: context,
    builder: (context) => DeleteCardDialog(question: question),
  );

  return isConfirmed ?? false;
}

class DeleteCardDialog extends StatelessWidget {
  const DeleteCardDialog({required this.question, super.key});

  final String question;

  Widget _subject(DesignColors colors) {
    return Container(
      padding: _blockPadding,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: colors.line, width: _subjectEdgeWidth),
        ),
      ),
      child: Text(
        question,
        style: textStyleForSize(TextSizes.small)
            .copyWith(color: colors.ink, height: baseLineHeight),
      ),
    );
  }

  Widget _warning(DesignColors colors) {
    return InsetBlock(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.step3,
        children: [
          DesignIcon(
            DesignIcons.failure,
            size: IconSizes.small,
            color: colors.danger,
          ),
          Expanded(
            child: Text(
              'Its review history goes too, so this cannot be undone. '
              'The rest of the deck is untouched.',
              style: textStyleForSize(TextSizes.small)
                  .copyWith(color: colors.inkSecondary, height: baseLineHeight),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return DesignModal(
      title: 'Delete this card?',
      description: 'It leaves the deck for good.',
      width: ModalWidth.wide,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.step4,
        children: [_subject(colors), _warning(colors)],
      ),
      actions: [
        DesignButton(
          label: 'Keep card',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        DesignButton(
          label: 'Delete card',
          variant: ButtonVariant.danger,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
