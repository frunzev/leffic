import 'package:flutter/material.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';
import '../../shared/design/segmented_control.dart';
import '../../shared/settings/chat_engine_choice.dart';
import 'ruled_block.dart';

const String chatEngineRestartNote = 'Changing the engine restarts Leffic.';
const List<ChatEngineChoice> _offeredEngines = [
  ChatEngineChoice.claudeCode,
  ChatEngineChoice.openAi,
];

String _labelOf(ChatEngineChoice engine) => engine.label;

class ChatEngineRow extends StatelessWidget {
  const ChatEngineRow({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final ChatEngineChoice selected;
  final ValueChanged<ChatEngineChoice> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = DesignColors.of(context);

    return RuledBlock(
      child: Row(
        spacing: Spacing.step3,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Spacing.step1,
              children: [
                Text(
                  'Chat engine',
                  style: textStyleForSize(TextSizes.medium)
                      .copyWith(color: colors.ink),
                ),
                Text(
                  chatEngineRestartNote,
                  style: textStyleForSize(TextSizes.small)
                      .copyWith(color: colors.inkTertiary),
                ),
              ],
            ),
          ),
          SegmentedControl<ChatEngineChoice>(
            choices: _offeredEngines,
            labelOf: _labelOf,
            selected: selected,
            onSelected: onSelected,
          ),
        ],
      ),
    );
  }
}
