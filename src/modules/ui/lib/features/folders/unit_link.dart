import 'package:flutter/widgets.dart';

import '../../shared/design/design_colors.dart';
import '../../shared/design/design_metrics.dart';
import '../../shared/design/design_typography.dart';
import '../../shared/design/focus_outline.dart';
import '../../shared/design/icons/design_icon.dart';
import '../../shared/design/pressable.dart';
import 'folder_models.dart';
import 'unit_badge.dart';
import 'unit_presentation.dart';

const double unitRowMinimumHeight = 52;
const double _linkOutlineRadius = 0;
const EdgeInsets _linkPadding = EdgeInsets.fromLTRB(
  Spacing.step4,
  0,
  Spacing.step2,
  0,
);

class UnitLink extends StatelessWidget {
  const UnitLink({
    required this.unit,
    required this.meta,
    required this.dueCount,
    required this.onOpen,
    super.key,
  });

  final FolderUnit unit;
  final String meta;
  final int dueCount;
  final VoidCallback onOpen;

  Widget _buildFace(BuildContext context, InteractionState state) {
    final colors = DesignColors.of(context);
    final nameDecoration = state.isHovered
        ? TextDecoration.underline
        : TextDecoration.none;
    final nameStyle = textStyleForSize(TextSizes.medium)
        .copyWith(color: colors.ink, decoration: nameDecoration);
    final metaStyle = textStyleForSize(TextSizes.extraSmall)
        .copyWith(color: colors.inkTertiary);

    return FocusOutline(
      state: state,
      borderRadius: _linkOutlineRadius,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: unitRowMinimumHeight),
        child: Padding(
          padding: _linkPadding,
          child: Row(
            spacing: Spacing.step3,
            children: [
              DesignIcon(iconForUnitType(unit.type), color: colors.inkTertiary),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.name,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: nameStyle,
                    ),
                    Text(meta, style: metaStyle),
                  ],
                ),
              ),
              if (dueCount > 0) UnitBadge(label: dueBadgeLabel(dueCount)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(onPressed: onOpen, builder: _buildFace);
  }
}
